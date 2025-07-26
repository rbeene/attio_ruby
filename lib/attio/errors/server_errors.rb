require_relative "base"

module Attio
  module Errors
    # 500 Internal Server Error
    class InternalServerError < Base
      def initialize(message = "An internal server error occurred", **args)
        super(message, **args)
      end
    end

    # 502 Bad Gateway
    class BadGatewayError < Base
      def initialize(message = "Bad gateway error occurred", **args)
        super(message, **args)
      end
    end

    # 503 Service Unavailable
    class ServiceUnavailableError < Base
      attr_reader :retry_after

      def initialize(message = "Service is temporarily unavailable", retry_after: nil, **args)
        @retry_after = retry_after
        super(message, **args)
      end

      def to_h
        super.tap do |hash|
          hash[:error][:retry_after] = retry_after if retry_after
        end
      end
    end

    # 504 Gateway Timeout
    class GatewayTimeoutError < Base
      def initialize(message = "Gateway timeout occurred", **args)
        super(message, **args)
      end
    end

    # Generic server error for other 5xx status codes
    class ServerError < Base
      def initialize(message = "Server error occurred", **args)
        super(message, **args)
      end
    end
  end
end