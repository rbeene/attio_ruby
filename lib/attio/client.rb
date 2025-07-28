# frozen_string_literal: true

require "faraday"
require "faraday/retry"
require "faraday/net_http_persistent"

module Attio
  # HTTP client for making requests to the Attio API
  # @api private
  class Client
    def initialize(api_key: nil)
      @api_key = api_key || Attio.configuration.api_key
      raise AuthenticationError, "No API key provided" unless @api_key
    end

    def get(path, params = {})
      request(:get, path, params)
    end

    def post(path, body = {})
      request(:post, path, body)
    end

    def put(path, body = {})
      request(:put, path, body)
    end

    def patch(path, body = {})
      request(:patch, path, body)
    end

    def delete(path)
      request(:delete, path)
    end

    private

    def request(method, path, params_or_body = {})
      require_relative "util/rate_limit_handler"

      Util::RateLimitHandler.with_retry(
        max_attempts: Attio.configuration.max_retries,
        logger: Attio.configuration.logger
      ) do
        response = connection.send(method) do |req|
          req.url path

          case method
          when :get, :delete
            req.params = params_or_body if params_or_body.any?
          else
            req.body = params_or_body.to_json
          end
        end

        handle_response(response)
      end
    rescue Faraday::Error => e
      handle_error(e)
    end

    def connection
      @connection ||= build_connection
    end

    def build_connection
      Faraday.new(
        url: base_url,
        headers: default_headers
      ) do |faraday|
        faraday.request :json
        faraday.response :json, content_type: /\bjson$/

        faraday.request :retry,
          max: Attio.configuration.max_retries,
          interval: 0.5,
          backoff_factor: 2,
          exceptions: [Faraday::TimeoutError, Faraday::ConnectionFailed],
          retry_statuses: [429, 503]

        # Use custom logger that sanitizes sensitive data
        if Attio.configuration.debug && Attio.configuration.logger
          require_relative "util/request_logger"
          faraday.use Util::RequestLogger, Attio.configuration.logger,
            headers: true, bodies: true
        end

        faraday.options.timeout = Attio.configuration.timeout
        faraday.options.open_timeout = Attio.configuration.open_timeout

        faraday.ssl.verify = Attio.configuration.verify_ssl_certs
        faraday.ssl.ca_file = Attio.configuration.ca_bundle_path if Attio.configuration.ca_bundle_path

        faraday.adapter :net_http_persistent
      end
    end

    def base_url
      "#{Attio.configuration.api_base}/#{Attio.configuration.api_version}"
    end

    def default_headers
      {
        "Authorization" => "Bearer #{@api_key}",
        "User-Agent" => "Attio Ruby/#{Attio::VERSION}",
        "Accept" => "application/json",
        "Content-Type" => "application/json"
      }
    end

    def handle_response(response)
      case response.status
      when 200..299
        response.body
      when 400
        error_detail = extract_error_detail(response)
        raise BadRequestError.new("Bad request: #{error_detail}", response_to_hash(response))
      when 401
        error_detail = extract_error_detail(response)
        raise AuthenticationError.new("Authentication failed: #{error_detail}", response_to_hash(response))
      when 403
        error_detail = extract_error_detail(response)
        raise ForbiddenError.new("Access forbidden: #{error_detail}", response_to_hash(response))
      when 404
        error_detail = extract_error_detail(response)
        raise NotFoundError.new("Resource not found: #{error_detail}", response_to_hash(response))
      when 409
        error_detail = extract_error_detail(response)
        raise ConflictError.new("Resource conflict: #{error_detail}", response_to_hash(response))
      when 422
        error_detail = extract_error_detail(response)
        raise UnprocessableEntityError.new("Validation failed: #{error_detail}", response_to_hash(response))
      when 429
        retry_after = response.headers["retry-after"]
        error_detail = extract_error_detail(response)
        message = "Rate limit exceeded: #{error_detail}"
        message += " (retry after #{retry_after}s)" if retry_after
        raise RateLimitError.new(message, response_to_hash(response))
      when 500..599
        error_detail = extract_error_detail(response)
        raise ServerError.new("Server error: #{error_detail}", response_to_hash(response))
      else
        raise Error.new("Unexpected response status: #{response.status}", response_to_hash(response))
      end
    end

    def handle_error(error)
      case error
      when Faraday::TimeoutError
        raise TimeoutError, "Request timed out"
      when Faraday::ConnectionFailed
        raise ConnectionError, "Connection failed: #{error.message}"
      else
        raise ConnectionError, "Request failed: #{error.message}"
      end
    end

    def response_to_hash(response)
      {
        status: response.status,
        headers: response.headers,
        body: response.body
      }
    end

    def extract_error_detail(response)
      return "No error details available" unless response.body.is_a?(Hash)

      # Try various common error message fields
      error_message = response.body["error"] ||
        response.body["message"] ||
        response.body["error_description"] ||
        response.body.dig("error", "message")

      # Handle validation errors with field details
      if response.body["errors"].is_a?(Array) && !response.body["errors"].empty?
        error_details = response.body["errors"].map do |error|
          if error.is_a?(Hash)
            field = error["field"] || error["attribute"]
            message = error["message"] || error["error"]
            field ? "#{field}: #{message}" : message
          else
            error.to_s
          end
        end
        error_message = error_details.join(", ")
      elsif response.body["errors"].is_a?(Hash)
        error_details = response.body["errors"].map do |field, messages|
          messages = Array(messages)
          "#{field}: #{messages.join(", ")}"
        end
        error_message = error_details.join(", ")
      end

      error_message || "No error details available"
    end
  end
end
