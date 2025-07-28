# frozen_string_literal: true

module Attio
  module Util
    # Secure path building utilities to prevent injection attacks
    module PathBuilder
      class << self
        # Sanitize and validate a path segment
        # @param segment [String] The path segment to sanitize
        # @param segment_name [String] Name of the segment for error messages
        # @return [String] The sanitized segment
        def sanitize_segment(segment, segment_name = "segment")
          raise ArgumentError, "#{segment_name} cannot be nil" if segment.nil?

          segment_str = segment.to_s.strip
          raise ArgumentError, "#{segment_name} cannot be empty" if segment_str.empty?

          # Check for path traversal attempts
          if segment_str.include?("..") || segment_str.include?("./") || segment_str.include?("/.")
            raise ArgumentError, "Invalid #{segment_name}: contains path traversal characters"
          end

          # Check for URL encoding attacks
          if segment_str.include?("%2F") || segment_str.include?("%2f")
            raise ArgumentError, "Invalid #{segment_name}: contains encoded slashes"
          end

          # Ensure the segment doesn't contain unescaped special characters
          unless segment_str.match?(/\A[a-zA-Z0-9_\-\.]+\z/)
            raise ArgumentError, "Invalid #{segment_name}: contains invalid characters. Only alphanumeric, underscore, hyphen, and dot are allowed"
          end

          segment_str
        end

        # Build a safe path from segments
        # @param segments [Array<String>] Path segments to join
        # @return [String] The built path
        def build_path(*segments)
          segments.map { |segment| sanitize_segment(segment) }.join("/")
        end

        # Build a path with query parameters
        # @param path [String] The base path
        # @param params [Hash] Query parameters
        # @return [String] The path with query string
        def build_path_with_params(path, params = {})
          return path if params.empty?

          query_string = params.map do |key, value|
            "#{CGI.escape(key.to_s)}=#{CGI.escape(value.to_s)}"
          end.join("&")

          "#{path}?#{query_string}"
        end

        # Validate an ID format
        # @param id [String, Hash] The ID to validate
        # @param resource_type [String] The resource type for error messages
        # @return [String] The validated ID
        def validate_id(id, resource_type = "resource")
          case id
          when Hash
            # Handle nested ID structures
            id_key = id.keys.find { |k| k.to_s.end_with?("_id") }
            raise ArgumentError, "Invalid #{resource_type} ID structure" unless id_key
            validate_id(id[id_key], resource_type)
          when String
            sanitize_segment(id, "#{resource_type} ID")
          when nil
            raise ArgumentError, "#{resource_type} ID cannot be nil"
          else
            raise ArgumentError, "Invalid #{resource_type} ID type: #{id.class}"
          end
        end

        # Build a resource path with proper validation
        # @param base [String] The base resource path
        # @param segments [Array] Additional path segments
        # @return [String] The complete resource path
        def build_resource_path(base, *segments)
          all_segments = [base] + segments.compact
          build_path(*all_segments)
        end
      end
    end
  end
end
