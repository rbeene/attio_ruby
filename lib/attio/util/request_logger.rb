# frozen_string_literal: true

module Attio
  module Util
    # Custom logger for API requests that sanitizes sensitive data
    # @api private
    class RequestLogger < Faraday::Middleware
      SENSITIVE_HEADERS = %w[authorization api-key x-api-key].freeze
      SENSITIVE_PARAMS = %w[api_key access_token refresh_token client_secret password].freeze
      SANITIZED_VALUE = "[FILTERED]"

      def initialize(app, logger = nil, options = {})
        super(app)
        @logger = logger || Attio.configuration.logger
        @log_headers = options.fetch(:headers, true)
        @log_bodies = options.fetch(:bodies, true)
        @log_errors = options.fetch(:errors, true)
      end

      def call(env)
        start_time = Time.now
        log_request(env)

        @app.call(env).on_complete do |response_env|
          duration = Time.now - start_time
          log_response(response_env, duration)
        end
      rescue => e
        log_error(e) if @log_errors
        raise
      end

      private

      def log_request(env)
        return unless @logger

        info = ["Attio API Request"]
        info << "#{env.method.upcase} #{env.url.path}"

        if env.url.query && !env.url.query.empty?
          info << "Query: #{sanitize_params(Faraday::Utils.parse_query(env.url.query))}"
        end

        if @log_headers
          info << "Headers: #{sanitize_headers(env.request_headers)}"
        end

        if @log_bodies && env.body
          info << "Body: #{sanitize_body(env.body)}"
        end

        @logger.info(info.join(" | "))
      end

      def log_response(env, duration)
        return unless @logger

        info = ["Attio API Response"]
        info << "Status: #{env.status}"
        info << "Duration: #{(duration * 1000).round(2)}ms"

        if @log_headers
          info << "Headers: #{sanitize_headers(env.response_headers)}"
        end

        if @log_bodies && env.body
          info << "Body: #{sanitize_body(env.body)}"
        end

        @logger.info(info.join(" | "))
      end

      def log_error(error)
        return unless @logger

        @logger.error("Attio API Error: #{error.class} - #{error.message}")
      end

      def sanitize_headers(headers)
        return {} unless headers

        headers.transform_keys(&:downcase).transform_values do |value|
          key = headers.keys.find { |k| k.to_s.downcase == value }
          SENSITIVE_HEADERS.include?(key.to_s.downcase) ? SANITIZED_VALUE : value
        end
      end

      def sanitize_params(params)
        return {} unless params

        params.transform_values do |value|
          key = params.keys.find { |k| k.to_s.downcase.include?("key") || k.to_s.downcase.include?("token") }
          (key || SENSITIVE_PARAMS.include?(key.to_s.downcase)) ? SANITIZED_VALUE : value
        end
      end

      def sanitize_body(body)
        case body
        when String
          begin
            json = JSON.parse(body)
            sanitize_json(json).to_json
          rescue JSON::ParserError
            # Not JSON, check if it contains sensitive patterns
            body.gsub(/(?:api_key|access_token|refresh_token|password)=([^&\s]+)/, '\1=' + SANITIZED_VALUE)
          end
        when Hash
          sanitize_json(body).to_json
        else
          body.to_s
        end
      end

      def sanitize_json(obj)
        case obj
        when Hash
          obj.transform_values do |value|
            key = obj.keys.find { |k| SENSITIVE_PARAMS.any? { |sp| k.to_s.downcase.include?(sp) } }
            if key
              SANITIZED_VALUE
            else
              ((value.is_a?(Hash) || value.is_a?(Array)) ? sanitize_json(value) : value)
            end
          end
        when Array
          obj.map { |item| sanitize_json(item) }
        else
          obj
        end
      end
    end
  end
end
