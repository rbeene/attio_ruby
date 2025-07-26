# frozen_string_literal: true

require "uri"
require "securerandom"
require "base64"

module Attio
  module OAuth
    class Client
      OAUTH_BASE_URL = "https://app.attio.com/authorize"
      TOKEN_URL = "https://api.attio.com/v2/oauth/token"
      DEFAULT_SCOPES = %w[
        record:read
        record:write
        object:read
        object:write
        list:read
        list:write
        webhook:read
        webhook:write
        user:read
      ].freeze

      attr_reader :client_id, :client_secret, :redirect_uri

      def initialize(client_id:, client_secret:, redirect_uri:)
        @client_id = client_id
        @client_secret = client_secret
        @redirect_uri = redirect_uri
        @connection_manager = Attio.connection_manager
        validate_config!
      end

      # Generate authorization URL for OAuth flow
      def authorization_url(scopes: DEFAULT_SCOPES, state: nil, extras: {})
        state ||= generate_state
        scopes = validate_scopes(scopes)

        params = {
          client_id: client_id,
          redirect_uri: redirect_uri,
          response_type: "code",
          scope: scopes.join(" "),
          state: state
        }.merge(extras)

        uri = URI.parse(OAUTH_BASE_URL)
        uri.query = URI.encode_www_form(params)

        {
          url: uri.to_s,
          state: state
        }
      end

      # Exchange authorization code for access token
      def exchange_code_for_token(code:, state: nil)
        raise ArgumentError, "Authorization code is required" if code.nil? || code.empty?

        params = {
          grant_type: "authorization_code",
          code: code,
          redirect_uri: redirect_uri,
          client_id: client_id,
          client_secret: client_secret
        }

        response = make_token_request(params)
        Token.new(response.merge(client: self))
      end

      # Refresh an existing access token
      def refresh_token(refresh_token)
        raise ArgumentError, "Refresh token is required" if refresh_token.nil? || refresh_token.empty?

        params = {
          grant_type: "refresh_token",
          refresh_token: refresh_token,
          client_id: client_id,
          client_secret: client_secret
        }

        response = make_token_request(params)
        Token.new(response.merge(client: self))
      end

      # Revoke a token
      def revoke_token(token)
        token_value = token.is_a?(Token) ? token.access_token : token

        params = {
          token: token_value,
          client_id: client_id,
          client_secret: client_secret
        }

        request = Util::RequestBuilder.build(
          method: :POST,
          path: "/oauth/revoke",
          params: params,
          api_key: "oauth" # OAuth endpoints don't use API keys
        )

        @connection_manager.execute(request)
        true
      rescue Error
        # Token might already be revoked
        false
      rescue
        # Catch any other errors
        false
      end

      # Validate token with introspection endpoint
      def introspect_token(token)
        token_value = token.is_a?(Token) ? token.access_token : token

        params = {
          token: token_value,
          client_id: client_id,
          client_secret: client_secret
        }

        request = Util::RequestBuilder.build(
          method: :POST,
          path: "/oauth/introspect",
          params: params,
          api_key: "oauth" # OAuth endpoints don't use API keys
        )

        response = @connection_manager.execute(request)
        Util::ResponseParser.parse(response)
      end

      private

      def validate_config!
        raise ArgumentError, "client_id is required" if client_id.nil? || client_id.empty?
        raise ArgumentError, "client_secret is required" if client_secret.nil? || client_secret.empty?
        raise ArgumentError, "redirect_uri is required" if redirect_uri.nil? || redirect_uri.empty?

        unless redirect_uri.start_with?("http://", "https://")
          raise ArgumentError, "redirect_uri must be a valid HTTP(S) URL"
        end
      end

      def validate_scopes(scopes)
        scopes = Array(scopes).map(&:to_s)
        return DEFAULT_SCOPES if scopes.empty?

        invalid_scopes = scopes - ScopeValidator::VALID_SCOPES
        unless invalid_scopes.empty?
          raise ArgumentError, "Invalid scopes: #{invalid_scopes.join(", ")}"
        end

        scopes
      end

      def generate_state
        SecureRandom.urlsafe_base64(32)
      end

      def make_token_request(params)
        request = {
          method: :POST,
          uri: URI.parse(TOKEN_URL),
          headers: {
            "Content-Type" => "application/x-www-form-urlencoded",
            "Accept" => "application/json"
          },
          body: URI.encode_www_form(params)
        }

        response = @connection_manager.execute(request)
        Util::ResponseParser.parse(response)
      end
    end
  end
end
