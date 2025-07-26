# frozen_string_literal: true

require "faraday"
require "faraday/retry"

module Attio
  module Util
    class FaradayConnectionManager
      def initialize
        @connections = {}
        @mutex = Mutex.new
      end

      def execute(request)
        uri = request[:uri]
        
        connection = get_connection(uri)
        
        response = connection.send(request[:method].downcase) do |req|
          req.url uri.request_uri
          req.headers = request[:headers]
          req.body = request[:body] if request[:body]
        end

        {
          status: response.status,
          headers: response.headers.transform_keys(&:downcase),
          body: response.body
        }
      rescue Faraday::Error => e
        raise ErrorFactory.from_exception(e, request_context(request))
      end

      private

      def get_connection(uri)
        base_url = "#{uri.scheme}://#{uri.host}:#{uri.port}"
        
        @mutex.synchronize do
          @connections[base_url] ||= build_connection(base_url)
        end
      end

      def build_connection(base_url)
        Faraday.new(url: base_url) do |faraday|
          # Configure SSL
          faraday.ssl.verify = Attio.configuration.verify_ssl_certs
          faraday.ssl.ca_file = Attio.configuration.ca_bundle_path if Attio.configuration.ca_bundle_path

          # Configure timeouts
          faraday.options.open_timeout = Attio.configuration.open_timeout
          faraday.options.timeout = Attio.configuration.timeout

          # Add retry middleware
          faraday.request :retry,
            max: Attio.configuration.max_retries || 3,
            interval: 0.5,
            max_interval: 10,
            backoff_factor: 2,
            exceptions: [
              Faraday::TimeoutError,
              Faraday::ConnectionFailed,
              Faraday::ServerError
            ]

          # Add logging if debug mode
          faraday.response :logger, Attio.configuration.logger, headers: true, bodies: true if Attio.configuration.debug

          # Use Net::HTTP adapter (default)
          faraday.adapter Faraday.default_adapter
        end
      end

      def request_context(request)
        {
          url: request[:uri].to_s,
          method: request[:method],
          params: request[:params],
          headers: request[:headers]
        }
      end
    end
  end
end