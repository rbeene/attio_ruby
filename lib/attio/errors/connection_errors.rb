require_relative "base"

module Attio
  module Errors
    # Network connection errors
    class ConnectionError < Base
      def initialize(message = "Network connection error occurred", **args)
        super(message, **args)
      end
    end

    # Timeout errors
    class TimeoutError < ConnectionError
      def initialize(message = "Request timed out", **args)
        super(message, **args)
      end
    end

    # SSL/TLS errors
    class SSLError < ConnectionError
      def initialize(message = "SSL/TLS connection error occurred", **args)
        super(message, **args)
      end
    end

    # DNS resolution errors
    class DNSError < ConnectionError
      def initialize(message = "DNS resolution failed", **args)
        super(message, **args)
      end
    end

    # Socket errors
    class SocketError < ConnectionError
      def initialize(message = "Socket error occurred", **args)
        super(message, **args)
      end
    end
  end
end