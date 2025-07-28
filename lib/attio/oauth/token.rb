# frozen_string_literal: true

module Attio
  module OAuth
    # Represents an OAuth access token with refresh capabilities
    class Token
      attr_reader :access_token, :refresh_token, :token_type, :expires_in,
        :expires_at, :scope, :created_at, :client

      def initialize(attributes = {})
        # Since this doesn't inherit from Resources::Base, we need to normalize
        normalized_attrs = normalize_attributes(attributes)
        @access_token = normalized_attrs[:access_token]
        @refresh_token = normalized_attrs[:refresh_token]
        @token_type = normalized_attrs[:token_type] || "Bearer"
        @expires_in = normalized_attrs[:expires_in]&.to_i
        @scope = parse_scope(normalized_attrs[:scope])
        @created_at = normalized_attrs[:created_at] || Time.now.utc
        @client = normalized_attrs[:client]

        calculate_expiration!
        validate!
      end

      def expired?
        return false if @expires_at.nil?
        Time.now.utc >= @expires_at
      end

      def expires_soon?(threshold = 300)
        return false if @expires_at.nil?
        Time.now.utc >= (@expires_at - threshold)
      end

      def refresh!
        raise InvalidTokenError, "No refresh token available" unless @refresh_token
        raise InvalidTokenError, "No OAuth client configured" unless @client

        new_token = @client.refresh_token(@refresh_token)
        update_from(new_token)
        self
      end

      def revoke!
        raise InvalidTokenError, "No OAuth client configured" unless @client

        @client.revoke_token(self)
        @access_token = nil
        @refresh_token = nil
        true
      end

      # Convert token to hash representation
      # @return [Hash] Token attributes as a hash
      def to_h
        {
          access_token: @access_token,
          refresh_token: @refresh_token,
          token_type: @token_type,
          expires_in: @expires_in,
          expires_at: @expires_at&.iso8601,
          scope: @scope,
          created_at: @created_at.iso8601
        }.compact
      end

      # Convert token to JSON string
      # @param opts [Hash] Options to pass to JSON.generate
      # @return [String] JSON representation of the token
      def to_json(*opts)
        JSON.generate(to_h, *opts)
      end

      # Human-readable representation with masked token
      # @return [String] Inspection string with partially masked token
      def inspect
        "#<#{self.class.name}:#{object_id} " \
          "token=#{@access_token ? "***" + @access_token[-4..] : "nil"} " \
          "expires_at=#{@expires_at&.iso8601} " \
          "scope=#{@scope.join(" ")}>"
      end

      # Authorization header value
      def authorization_header
        "#{@token_type} #{@access_token}"
      end

      # Check if token has specific scope
      def has_scope?(scope)
        @scope.include?(scope.to_s)
      end

      # Store token securely (subclasses can override)
      def save
        # Default implementation does nothing
        # Subclasses can implement secure storage
        self
      end

      # Load token from secure storage (class method)
      def self.load(identifier = nil)
        # Default implementation returns nil
        # Subclasses can implement secure retrieval
        nil
      end

      private

      def calculate_expiration!
        @expires_at = if @expires_in
          @created_at + @expires_in
        end
      end

      def parse_scope(scope)
        case scope
        when String
          scope.split(" ")
        when Array
          scope.map(&:to_s)
        else
          []
        end
      end

      def validate!
        raise InvalidTokenError, "Access token is required" if @access_token.nil? || @access_token.empty?
        raise InvalidTokenError, "Invalid token type" unless %w[Bearer bearer].include?(@token_type)
      end

      def update_from(other_token)
        @access_token = other_token.access_token
        @refresh_token = other_token.refresh_token if other_token.refresh_token
        @token_type = other_token.token_type
        @expires_in = other_token.expires_in
        @expires_at = other_token.expires_at
        @scope = other_token.scope
        @created_at = other_token.created_at
      end

      def normalize_attributes(attributes)
        return {} unless attributes

        attributes.each_with_object({}) do |(key, value), hash|
          hash[key.to_sym] = value
        end
      end

      # Raised when token validation fails
      class InvalidTokenError < StandardError; end
    end
  end
end
