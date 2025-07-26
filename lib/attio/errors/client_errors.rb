# frozen_string_literal: true

require_relative "base"

module Attio
  module Errors
    # 400 Bad Request
    class BadRequestError < Base
      def initialize(message = "The request was invalid or cannot be served", **args)
        super
      end
    end

    # 401 Unauthorized
    class AuthenticationError < Base
      def initialize(message = "Authentication failed. Please check your API key", **args)
        super
      end
    end

    # 403 Forbidden
    class ForbiddenError < Base
      def initialize(message = "You do not have permission to access this resource", **args)
        super
      end
    end

    # 404 Not Found
    class NotFoundError < Base
      def initialize(message = "The requested resource could not be found", **args)
        super
      end
    end

    # 409 Conflict
    class ConflictError < Base
      def initialize(message = "The request conflicts with the current state of the resource", **args)
        super
      end
    end

    # 422 Unprocessable Entity
    class UnprocessableEntityError < Base
      def initialize(message = "The request was well-formed but contains semantic errors", **args)
        super
      end
    end

    # 429 Too Many Requests
    class RateLimitError < Base
      attr_reader :retry_after

      def initialize(message = "Rate limit exceeded", retry_after: nil, **args)
        @retry_after = retry_after
        super(message, **args)
      end

      def to_h
        super.tap do |hash|
          hash[:error][:retry_after] = retry_after if retry_after
        end
      end
    end

    # Generic client error for other 4xx status codes
    class ClientError < Base
      def initialize(message = "Client error occurred", **args)
        super
      end
    end

    # Validation error with field-level details
    class ValidationError < UnprocessableEntityError
      attr_reader :errors

      def initialize(message = "Validation failed", errors: {}, **args)
        @errors = errors
        super(build_validation_message(message, errors), **args)
      end

      def to_h
        super.tap do |hash|
          hash[:error][:validation_errors] = errors unless errors.empty?
        end
      end

      private

      def build_validation_message(base_message, errors)
        return base_message if errors.empty?

        error_messages = errors.map do |field, messages|
          messages = [messages] unless messages.is_a?(Array)
          "#{field}: #{messages.join(", ")}"
        end

        "#{base_message} - #{error_messages.join("; ")}"
      end
    end

    # Invalid request error
    class InvalidRequestError < BadRequestError
      def initialize(message = "Invalid request parameters", **args)
        super
      end
    end
  end
end
