# frozen_string_literal: true

module Attio
  # Base error class for all Attio errors
  class Error < StandardError
    attr_reader :response, :code, :request_id

    def initialize(message, response = nil)
      @response = response

      if response
        @code = response[:status]
        @request_id = extract_request_id(response)

        # Try to extract a better error message from the response
        if response[:body].is_a?(Hash)
          api_message = response[:body][:error] || response[:body][:message]
          message = "#{message}: #{api_message}" if api_message
        end
      end

      super(message)
    end

    private

    def extract_request_id(response)
      return nil unless response[:headers]
      response[:headers]["x-request-id"] || response[:headers]["X-Request-Id"]
    end
  end

  # Client errors (4xx)
  class ClientError < Error; end

  # Specific client errors
  class BadRequestError < ClientError; end          # 400

  class AuthenticationError < ClientError; end      # 401

  class ForbiddenError < ClientError; end          # 403

  class NotFoundError < ClientError; end           # 404

  class ConflictError < ClientError; end           # 409

  class UnprocessableEntityError < ClientError; end # 422

  class RateLimitError < ClientError               # 429
    attr_reader :retry_after

    def initialize(message, response = nil)
      super
      @retry_after = extract_retry_after(response) if response
    end

    private

    def extract_retry_after(response)
      return nil unless response[:headers]
      value = response[:headers]["retry-after"] || response[:headers]["Retry-After"]
      value&.to_i
    end
  end

  # Server errors (5xx)
  class ServerError < Error; end

  # Connection errors
  class ConnectionError < Error; end

  # Request timeout error
  class TimeoutError < ConnectionError; end

  # Network-level connection error
  class NetworkError < ConnectionError; end

  # Configuration errors
  class ConfigurationError < Error; end

  # Request errors
  class InvalidRequestError < ClientError; end

  # Factory module for creating appropriate error instances
  module ErrorFactory
    # Create an error instance from an HTTP response
    # @param response [Hash] Response hash with :status, :body, and :headers
    # @param message [String, nil] Optional custom error message
    # @return [Error] Appropriate error instance based on status code
    def self.from_response(response, message = nil)
      status = response[:status].to_i
      message ||= "API request failed with status #{status}"

      case status
      when 400 then BadRequestError.new(message, response)
      when 401 then AuthenticationError.new(message, response)
      when 403 then ForbiddenError.new(message, response)
      when 404 then NotFoundError.new(message, response)
      when 409 then ConflictError.new(message, response)
      when 422 then UnprocessableEntityError.new(message, response)
      when 429 then RateLimitError.new(message, response)
      when 400..499 then ClientError.new(message, response)
      when 500..599 then ServerError.new(message, response)
      else
        Error.new(message, response)
      end
    end

    # Create an error instance from a caught exception
    # @param exception [Exception] The caught exception
    # @param context [Hash] Additional context (currently unused)
    # @return [Error] Appropriate error instance based on exception type
    def self.from_exception(exception, context = {})
      case exception
      when Faraday::TimeoutError, Net::ReadTimeout, Net::OpenTimeout
        TimeoutError.new("Request timed out: #{exception.message}")
      when Faraday::ConnectionFailed, SocketError, Errno::ECONNREFUSED
        NetworkError.new("Network error: #{exception.message}")
      when Faraday::ClientError
        from_response({status: exception.response_status, body: exception.response_body})
      else
        ConnectionError.new("Connection error: #{exception.message}")
      end
    end
  end
end
