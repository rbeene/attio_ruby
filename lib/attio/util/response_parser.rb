# frozen_string_literal: true

require "json"

module Attio
  module Util
    class ResponseParser
      def self.parse(response, request_context = {})
        new(response, request_context).parse
      end

      def initialize(response, request_context = {})
        @response = response
        @request_context = request_context
        @status = response[:status]
        @headers = response[:headers] || {}
        @body = response[:body]
      end

      def parse
        if success?
          parse_success_response
        else
          parse_error_response
        end
      end

      private

      def success?
        @status >= 200 && @status < 300
      end

      def parse_success_response
        return nil if @body.nil? || @body.empty?

        begin
          parsed_body = JSON.parse(@body, symbolize_names: true)
          
          # Handle paginated responses
          if parsed_body.is_a?(Hash) && parsed_body.key?(:data) && parsed_body.key?(:pagination)
            {
              data: parsed_body[:data],
              pagination: parse_pagination(parsed_body[:pagination]),
              _raw: parsed_body
            }
          else
            parsed_body
          end
        rescue JSON::ParserError => e
          raise Errors::InvalidResponseError.new(
            "Invalid JSON response: #{e.message}",
            http_status: @status,
            http_body: @body,
            response_headers: @headers
          )
        end
      end

      def parse_error_response
        error = Errors::ErrorFactory.from_response(@response, @request_context)
        
        # Add rate limit information if available
        if error.is_a?(Errors::RateLimitError) && @headers["retry-after"]
          error.instance_variable_set(:@retry_after, @headers["retry-after"].to_i)
        end
        
        raise error
      end

      def parse_pagination(pagination_data)
        return nil unless pagination_data.is_a?(Hash)

        {
          has_next_page: pagination_data[:has_next_page] || false,
          has_previous_page: pagination_data[:has_previous_page] || false,
          page_size: pagination_data[:page_size],
          total_count: pagination_data[:total_count],
          next_cursor: pagination_data[:next_cursor],
          previous_cursor: pagination_data[:previous_cursor]
        }.compact
      end
    end

    # Custom error for invalid responses
    class InvalidResponseError < Errors::Base
      def initialize(message = "Invalid response from Attio API", **args)
        super(message, **args)
      end
    end
  end
end