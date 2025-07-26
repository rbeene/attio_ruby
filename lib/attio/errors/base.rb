# frozen_string_literal: true

module Attio
  module Errors
    class Base < StandardError
      attr_reader :message, :code, :request_id, :http_status, :http_body, :json_body,
        :request_url, :request_method, :request_params, :request_headers,
        :response_headers, :occurred_at

      def initialize(message = nil, code: nil, request_id: nil, http_status: nil,
        http_body: nil, json_body: nil, request_url: nil,
        request_method: nil, request_params: nil, request_headers: nil,
        response_headers: nil)
        @message = message
        @code = code
        @request_id = request_id
        @http_status = http_status
        @http_body = http_body
        @json_body = json_body
        @request_url = request_url
        @request_method = request_method
        @request_params = request_params
        @request_headers = request_headers
        @response_headers = response_headers
        @occurred_at = Time.now.utc

        super(build_message)
      end

      def to_h
        {
          error: {
            type: self.class.name.split("::").last,
            message: message,
            code: code,
            request_id: request_id,
            http_status: http_status,
            occurred_at: occurred_at.iso8601
          }.compact,
          request: {
            url: request_url,
            method: request_method,
            params: request_params,
            headers: sanitized_request_headers
          }.compact,
          response: {
            headers: response_headers,
            body: truncated_body
          }.compact
        }.reject { |_, v| v.empty? }
      end

      def to_json(*_args)
        JSON.generate(to_h)
      end

      def inspect
        "#<#{self.class.name}:#{object_id} #{build_inspect_string}>"
      end

      private

      def build_message
        parts = []
        parts << message if message
        parts << "(Code: #{code})" if code
        parts << "(Status: #{http_status})" if http_status
        parts << "(Request ID: #{request_id})" if request_id
        parts.join(" ")
      end

      def build_inspect_string
        attrs = []
        attrs << "message=#{message.inspect}" if message
        attrs << "code=#{code.inspect}" if code
        attrs << "http_status=#{http_status}" if http_status
        attrs << "request_id=#{request_id.inspect}" if request_id
        attrs.join(" ")
      end

      def sanitized_request_headers
        return nil unless request_headers

        request_headers.transform_values do |value|
          if value.to_s.match?(/api[-_]?key|auth|token|secret|password/i)
            "[REDACTED]"
          else
            value
          end
        end
      end

      def truncated_body
        return nil unless http_body

        if http_body.length > 1000
          "#{http_body[0...1000]}... (truncated)"
        else
          http_body
        end
      end

      class << self
        def from_response(response, context = {})
          body = response[:body]
          headers = response[:headers]
          status = response[:status]

          json_body = parse_json(body)
          error_data = extract_error_data(json_body, body)

          new(
            error_data[:message],
            code: error_data[:code],
            request_id: headers["x-request-id"] || headers["request-id"],
            http_status: status,
            http_body: body,
            json_body: json_body,
            request_url: context[:url],
            request_method: context[:method],
            request_params: context[:params],
            request_headers: context[:headers],
            response_headers: headers
          )
        end

        private

        def parse_json(body)
          return nil if body.nil? || body.empty?

          JSON.parse(body, symbolize_names: true)
        rescue JSON::ParserError
          nil
        end

        def extract_error_data(json_body, raw_body)
          if json_body&.is_a?(Hash)
            {
              message: json_body[:error] || json_body[:message] || raw_body,
              code: json_body[:code] || json_body[:error_code]
            }
          else
            {
              message: raw_body,
              code: nil
            }
          end
        end
      end
    end
  end
end
