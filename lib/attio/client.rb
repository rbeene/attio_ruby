# frozen_string_literal: true

require "faraday"
require "faraday/retry"

module Attio
  # HTTP client for making API requests to Attio
  # Handles authentication, retries, and error responses
  class Client
    def initialize(api_key: nil)
      @api_key = api_key || Attio.configuration.api_key
      raise AuthenticationError, "No API key provided" unless @api_key
    end

    # Perform a GET request
    # @param path [String] The API endpoint path
    # @param params [Hash] Query parameters
    # @return [Hash] Parsed JSON response
    # @raise [Error] On API errors
    def get(path, params = {})
      request(:get, path, params)
    end

    # Perform a POST request
    # @param path [String] The API endpoint path
    # @param body [Hash] Request body to be sent as JSON
    # @return [Hash] Parsed JSON response
    # @raise [Error] On API errors
    def post(path, body = {})
      request(:post, path, body)
    end

    # Perform a PUT request
    # @param path [String] The API endpoint path
    # @param body [Hash] Request body to be sent as JSON
    # @return [Hash] Parsed JSON response
    # @raise [Error] On API errors
    def put(path, body = {})
      request(:put, path, body)
    end

    # Perform a PATCH request
    # @param path [String] The API endpoint path
    # @param body [Hash] Request body to be sent as JSON
    # @return [Hash] Parsed JSON response
    # @raise [Error] On API errors
    def patch(path, body = {})
      request(:patch, path, body)
    end

    # Perform a DELETE request
    # @param path [String] The API endpoint path
    # @return [Hash] Parsed JSON response
    # @raise [Error] On API errors
    def delete(path)
      request(:delete, path)
    end

    private

    def request(method, path, params_or_body = {})
      response = connection.send(method) do |req|
        req.url path

        case method
        when :get, :delete
          req.params = params_or_body if params_or_body.any?
        else
          req.body = params_or_body.to_json
          puts "DEBUG: Request body: #{req.body}" if ENV["ATTIO_DEBUG"]
        end
      end

      handle_response(response)
    rescue Faraday::Error => e
      handle_error(e)
    end

    def connection
      @connection ||= Faraday.new(
        url: base_url,
        headers: default_headers
      ) do |faraday|
        faraday.request :json
        faraday.response :json, content_type: /\bjson$/

        faraday.request :retry,
          max: Attio.configuration.max_retries,
          interval: 0.5,
          backoff_factor: 2,
          exceptions: [Faraday::TimeoutError, Faraday::ConnectionFailed]

        faraday.response :logger, Attio.configuration.logger if Attio.configuration.debug

        faraday.options.timeout = Attio.configuration.timeout
        faraday.options.open_timeout = Attio.configuration.open_timeout

        faraday.ssl.verify = Attio.configuration.verify_ssl_certs
        faraday.ssl.ca_file = Attio.configuration.ca_bundle_path if Attio.configuration.ca_bundle_path
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
        error_message = response.body["error"] || response.body["message"] || "Bad request"
        raise BadRequestError.new("Bad request: #{error_message}", response_to_hash(response))
      when 401
        raise AuthenticationError.new("Authentication failed", response_to_hash(response))
      when 403
        raise ForbiddenError.new("Access forbidden", response_to_hash(response))
      when 404
        raise NotFoundError.new("Resource not found", response_to_hash(response))
      when 409
        raise ConflictError.new("Resource conflict", response_to_hash(response))
      when 422
        raise UnprocessableEntityError.new("Unprocessable entity", response_to_hash(response))
      when 429
        raise RateLimitError.new("Rate limit exceeded", response_to_hash(response))
      when 500..599
        raise ServerError.new("Server error", response_to_hash(response))
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
  end
end
