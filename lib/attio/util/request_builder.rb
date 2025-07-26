# frozen_string_literal: true

require "json"
require "uri"
require "cgi"

module Attio
  module Util
    class RequestBuilder
      API_VERSION = "v2"
      BASE_HEADERS = {
        "User-Agent" => "Attio Ruby/#{Attio::VERSION}",
        "Accept" => "application/json",
        "Content-Type" => "application/json"
      }.freeze

      def self.build(method:, path:, params: nil, headers: {}, api_key: nil)
        new(method: method, path: path, params: params, headers: headers, api_key: api_key).build
      end

      def initialize(method:, path:, params: nil, headers: {}, api_key: nil)
        @method = method.to_s.upcase
        @path = path
        @params = params
        @headers = headers
        @api_key = api_key || Attio.configuration.api_key
      end

      def build
        validate_api_key!

        {
          method: @method,
          uri: build_uri,
          headers: build_headers,
          body: build_body,
          params: @params
        }
      end

      private

      def validate_api_key!
        return if @api_key && !@api_key.empty?

        raise Errors::AuthenticationError, "No API key provided. Set Attio.api_key or pass api_key option"
      end

      def build_uri
        base_url = Attio.configuration.api_base
        version = Attio.configuration.api_version || API_VERSION
        path = ensure_leading_slash(@path)

        uri_string = "#{base_url}/#{version}#{path}"

        if @method == "GET" && @params && !@params.empty?
          uri_string += "?#{encode_params(@params)}"
        end

        URI.parse(uri_string)
      end

      def build_headers
        headers = BASE_HEADERS.dup
        headers["Authorization"] = "Bearer #{@api_key}"
        headers["X-Request-ID"] = generate_request_id

        # Add custom headers
        @headers.each do |key, value|
          headers[normalize_header_key(key)] = value.to_s
        end

        headers
      end

      def build_body
        return nil if @method == "GET" || @method == "HEAD"
        return nil if @params.nil? || @params.empty?

        JSON.generate(normalize_params(@params))
      end

      def ensure_leading_slash(path)
        path.start_with?("/") ? path : "/#{path}"
      end

      def encode_params(params)
        normalized = normalize_params(params)
        flatten_params(normalized).map do |key, value|
          "#{CGI.escape(key)}=#{CGI.escape(value.to_s)}"
        end.join("&")
      end

      def flatten_params(params, parent_key = nil)
        result = {}

        params.each do |key, value|
          full_key = parent_key ? "#{parent_key}[#{key}]" : key.to_s

          case value
          when Hash
            result.merge!(flatten_params(value, full_key))
          when Array
            value.each_with_index do |item, index|
              if item.is_a?(Hash)
                result.merge!(flatten_params(item, "#{full_key}[#{index}]"))
              else
                result["#{full_key}[#{index}]"] = item
              end
            end
          else
            result[full_key] = value
          end
        end

        result
      end

      def normalize_params(params)
        case params
        when Hash
          params.transform_keys(&:to_s).transform_values { |v| normalize_params(v) }
        when Array
          params.map { |v| normalize_params(v) }
        when Symbol
          params.to_s
        else
          params
        end
      end

      def normalize_header_key(key)
        key.to_s.split(/[-_]/).map(&:capitalize).join("-")
      end

      def generate_request_id
        "req_#{SecureRandom.hex(16)}"
      end
    end
  end
end
