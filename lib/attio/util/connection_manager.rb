# frozen_string_literal: true

require "net/http"
require "net/https"
require "uri"

module Attio
  module Util
    class ConnectionManager
      KEEPALIVE_TIMEOUT = 30
      MAX_RETRIES = 3
      RETRY_DELAY = 0.5
      MAX_RETRY_DELAY = 10
      POOL_SIZE = 5

      class ConnectionPool
        def initialize(size: POOL_SIZE)
          @size = size
          @connections = {}
          @mutex = Mutex.new
          @last_used = {}
        end

        def with_connection(uri, &block)
          connection = checkout(uri)
          yield connection
        ensure
          checkin(uri, connection) if connection
        end

        private

        def checkout(uri)
          @mutex.synchronize do
            key = connection_key(uri)
            conn = @connections[key]

            if conn&.started? && !stale?(key)
              @last_used[key] = Time.now
              return conn
            end

            conn = create_connection(uri)
            @connections[key] = conn
            @last_used[key] = Time.now
            conn
          end
        end

        def checkin(uri, connection)
          @mutex.synchronize do
            key = connection_key(uri)
            @connections[key] = connection if connection.started?
            cleanup_stale_connections
          end
        end

        def create_connection(uri)
          http = Net::HTTP.new(uri.host, uri.port)
          configure_connection(http, uri)
          http.start
          http
        end

        def configure_connection(http, uri)
          http.use_ssl = uri.scheme == "https"
          http.verify_mode = OpenSSL::SSL::VERIFY_PEER
          http.ca_file = Attio.configuration.ca_bundle_path if Attio.configuration.ca_bundle_path
          http.verify_mode = OpenSSL::SSL::VERIFY_NONE unless Attio.configuration.verify_ssl_certs

          http.open_timeout = Attio.configuration.open_timeout
          http.read_timeout = Attio.configuration.timeout
          http.write_timeout = Attio.configuration.timeout if http.respond_to?(:write_timeout=)
          http.keep_alive_timeout = KEEPALIVE_TIMEOUT
        end

        def connection_key(uri)
          "#{uri.scheme}://#{uri.host}:#{uri.port}"
        end

        def stale?(key)
          return true unless @last_used[key]
          Time.now - @last_used[key] > KEEPALIVE_TIMEOUT
        end

        def cleanup_stale_connections
          @connections.each do |key, conn|
            if stale?(key)
              conn.finish if conn.started?
              @connections.delete(key)
              @last_used.delete(key)
            end
          end

          if @connections.size > @size
            oldest_key = @last_used.min_by { |_, time| time }&.first
            if oldest_key
              @connections[oldest_key].finish if @connections[oldest_key].started?
              @connections.delete(oldest_key)
              @last_used.delete(oldest_key)
            end
          end
        end
      end

      def initialize
        @pool = ConnectionPool.new(size: POOL_SIZE)
      end

      def execute(request)
        uri = request[:uri]
        http_method = request[:method]
        headers = request[:headers]
        body = request[:body]

        retries = 0
        last_error = nil

        loop do
          return perform_request(uri, http_method, headers, body)
        rescue *retryable_exceptions => e
          last_error = e
          retries += 1

          if retries >= max_retries
            raise ErrorFactory.from_exception(e, request_context(request))
          end

          sleep(calculate_retry_delay(retries))
        rescue => e
          raise ErrorFactory.from_exception(e, request_context(request))
        end
      end

      private

      def perform_request(uri, method, headers, body)
        @pool.with_connection(uri) do |http|
          request_class = request_class_for(method)
          request = request_class.new(uri.request_uri)

          headers.each { |k, v| request[k] = v }
          request.body = body if body && request.request_body_permitted?

          log_request(method, uri, headers, body) if Attio.configuration.debug

          response = http.request(request)

          log_response(response) if Attio.configuration.debug

          {
            status: response.code.to_i,
            headers: response_headers(response),
            body: response.body
          }
        end
      end

      def request_class_for(method)
        case method.to_s.upcase
        when "GET" then Net::HTTP::Get
        when "POST" then Net::HTTP::Post
        when "PUT" then Net::HTTP::Put
        when "PATCH" then Net::HTTP::Patch
        when "DELETE" then Net::HTTP::Delete
        when "HEAD" then Net::HTTP::Head
        else
          raise ArgumentError, "Unsupported HTTP method: #{method}"
        end
      end

      def response_headers(response)
        headers = {}
        response.each_header { |k, v| headers[k.downcase] = v }
        headers
      end

      def retryable_exceptions
        [
          Timeout::Error,
          Net::OpenTimeout,
          Net::ReadTimeout,
          Net::HTTPBadResponse,
          Net::HTTPHeaderSyntaxError,
          Net::ProtocolError,
          Errno::ECONNREFUSED,
          Errno::ECONNRESET,
          Errno::EHOSTUNREACH,
          Errno::ETIMEDOUT,
          SocketError
        ]
      end

      def max_retries
        Attio.configuration.max_retries || MAX_RETRIES
      end

      def calculate_retry_delay(retry_count)
        delay = RETRY_DELAY * (2**(retry_count - 1))
        [delay, MAX_RETRY_DELAY].min
      end

      def request_context(request)
        {
          url: request[:uri].to_s,
          method: request[:method],
          params: request[:params],
          headers: request[:headers]
        }
      end

      def log_request(method, uri, headers, body)
        return unless Attio.configuration.logger

        Attio.configuration.logger.debug "[Attio] Request: #{method.upcase} #{uri}"
        Attio.configuration.logger.debug "[Attio] Headers: #{sanitize_headers(headers)}"
        Attio.configuration.logger.debug "[Attio] Body: #{body}" if body
      end

      def log_response(response)
        return unless Attio.configuration.logger

        Attio.configuration.logger.debug "[Attio] Response: #{response.code} #{response.message}"
        Attio.configuration.logger.debug "[Attio] Headers: #{response.to_hash}"
        Attio.configuration.logger.debug "[Attio] Body: #{response.body}" if response.body
      end

      def sanitize_headers(headers)
        headers.transform_values do |value|
          if value.to_s.match?(/api[-_]?key|auth|token|secret|password/i)
            "[REDACTED]"
          else
            value
          end
        end
      end
    end
  end
end
