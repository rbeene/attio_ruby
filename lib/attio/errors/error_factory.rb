# frozen_string_literal: true

require_relative "base"
require_relative "client_errors"
require_relative "server_errors"
require_relative "connection_errors"

module Attio
  module Errors
    class ErrorFactory
      class << self
        def from_response(response, context = {})
          status = response[:status]
          error_class = error_class_for_status(status)
          error_class.from_response(response, context)
        end

        def from_exception(exception, context = {})
          case exception
          when Timeout::Error, Net::OpenTimeout, Net::ReadTimeout
            TimeoutError.new(
              "Request timed out: #{exception.message}",
              request_url: context[:url],
              request_method: context[:method],
              request_params: context[:params],
              request_headers: context[:headers]
            )
          when OpenSSL::SSL::SSLError
            SSLError.new(
              "SSL error: #{exception.message}",
              request_url: context[:url],
              request_method: context[:method],
              request_params: context[:params],
              request_headers: context[:headers]
            )
          when SocketError, Errno::ECONNREFUSED, Errno::EHOSTUNREACH
            SocketError.new(
              "Connection failed: #{exception.message}",
              request_url: context[:url],
              request_method: context[:method],
              request_params: context[:params],
              request_headers: context[:headers]
            )
          when Resolv::ResolvError, Resolv::ResolvTimeout
            DNSError.new(
              "DNS resolution failed: #{exception.message}",
              request_url: context[:url],
              request_method: context[:method],
              request_params: context[:params],
              request_headers: context[:headers]
            )
          else
            ConnectionError.new(
              "Connection error: #{exception.class.name} - #{exception.message}",
              request_url: context[:url],
              request_method: context[:method],
              request_params: context[:params],
              request_headers: context[:headers]
            )
          end
        end

        private

        def error_class_for_status(status)
          case status
          when 400
            BadRequestError
          when 401
            AuthenticationError
          when 403
            ForbiddenError
          when 404
            NotFoundError
          when 409
            ConflictError
          when 422
            UnprocessableEntityError
          when 429
            RateLimitError
          when 400..499
            ClientError
          when 500
            InternalServerError
          when 502
            BadGatewayError
          when 503
            ServiceUnavailableError
          when 504
            GatewayTimeoutError
          when 500..599
            ServerError
          else
            Base
          end
        end
      end
    end
  end
end
