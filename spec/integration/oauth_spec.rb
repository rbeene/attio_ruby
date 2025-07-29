# frozen_string_literal: true

require "spec_helper"

RSpec.describe "OAuth Integration", :integration do
  let(:client_id) { ENV["ATTIO_CLIENT_ID"] }
  let(:client_secret) { ENV["ATTIO_CLIENT_SECRET"] }
  let(:redirect_uri) { "http://localhost:3000/callback" }

  let(:oauth_client) do
    Attio::OAuth::Client.new(
      client_id: client_id,
      client_secret: client_secret,
      redirect_uri: redirect_uri
    )
  end

  describe "authorization flow" do
    let(:auth_params) do
      {
        scopes: %w[record:read record:write],
        state: "test-state-123"
      }
    end

    let(:auth_data) { oauth_client.authorization_url(**auth_params) }

    it "returns authorization data structure" do
      expect(auth_data).to have_key(:url)
      expect(auth_data).to have_key(:state)
    end

    it "uses correct OAuth endpoint" do
      expect(auth_data[:url]).to include("https://app.attio.com/authorize")
    end

    it "includes client_id in URL" do
      expect(auth_data[:url]).to include("client_id=#{client_id}")
    end

    it "includes redirect_uri in URL" do
      expect(auth_data[:url]).to include("redirect_uri=#{CGI.escape(redirect_uri)}")
    end

    it "includes encoded scopes in URL" do
      expect(auth_data[:url]).to include("scope=record%3Aread+record%3Awrite")
    end

    it "preserves state parameter" do
      expect(auth_data[:url]).to include("state=test-state-123")
      expect(auth_data[:state]).to eq("test-state-123")
    end

    it "generates state if not provided" do
      auth_data = oauth_client.authorization_url(scopes: %w[user:read])

      expect(auth_data[:state]).to be_truthy
      expect(auth_data[:state].length).to eq(32)
    end
  end

  describe "token exchange" do
    it "exchanges code for token", skip: "Requires valid authorization code" do
      # This would require a valid authorization code from the OAuth flow
      # In real integration tests, you'd need to simulate or provide this
      code = "test_authorization_code"

      token = oauth_client.exchange_code_for_token(code: code)

      expect(token).to be_a(Attio::OAuth::Token)
      expect(token.access_token).to be_truthy
      expect(token.token_type).to eq("Bearer")
      expect(token.expires_in).to be > 0
      expect(token.scope).to be_an(Array)
    end

    it "handles invalid code error" do
      expect {
        oauth_client.exchange_code_for_token(code: "invalid_code")
      }.to raise_error(Attio::AuthenticationError)
    end
  end

  describe "token refresh" do
    it "refreshes access token", skip: "Requires valid refresh token" do
      # This would require a valid refresh token
      refresh_token = "test_refresh_token"

      new_token = oauth_client.refresh_token(refresh_token)

      expect(new_token).to be_a(Attio::OAuth::Token)
      expect(new_token.access_token).to be_truthy
      expect(new_token.access_token).not_to eq(refresh_token)
    end

    it "handles invalid refresh token" do
      expect {
        oauth_client.refresh_token("invalid_refresh_token")
      }.to raise_error(Attio::AuthenticationError)
    end
  end

  describe "token introspection" do
    it "introspects valid token", skip: "Requires valid token" do
      token = "valid_access_token"

      info = oauth_client.introspect_token(token)

      expect(info[:active]).to be true
      expect(info[:token_type]).to eq("access_token")
      expect(info[:scope]).to be_truthy
      expect(info[:client_id]).to eq(client_id)
    end

    it "introspects invalid token" do
      info = oauth_client.introspect_token("invalid_token")

      expect(info[:active]).to be false
    end
  end

  describe "token revocation" do
    it "revokes access token", skip: "Requires valid token" do
      token = "valid_access_token"

      result = oauth_client.revoke_token(token)
      expect(result).to be true

      # Verify token is no longer valid
      info = oauth_client.introspect_token(token)
      expect(info[:active]).to be false
    end

    it "handles already revoked token" do
      # Revoking an already revoked or invalid token should still return true
      result = oauth_client.revoke_token("already_revoked_token")
      expect(result).to be true
    end
  end

  describe "using OAuth token with API" do
    it "makes authenticated requests", skip: "Requires valid OAuth token" do
      # Configure with OAuth token
      oauth_token = "valid_oauth_access_token"

      Attio.configure do |config|
        config.api_key = oauth_token
      end

      # Should be able to make API calls
      me = Attio::WorkspaceMember.me
      expect(me).to be_a(Attio::WorkspaceMember)
      expect(me.email_address).to be_truthy
    end

    it "handles expired token" do
      Attio.configure do |config|
        config.api_key = "expired_oauth_token"
      end

      expect {
        Attio::WorkspaceMember.me
      }.to raise_error(Attio::AuthenticationError) do |error|
        expect(error.message).to include("expired")
      end
    end
  end

  describe "OAuth error handling" do
    it "handles missing client credentials" do
      expect {
        Attio::OAuth::Client.new(
          client_id: nil,
          client_secret: client_secret,
          redirect_uri: redirect_uri
        )
      }.to raise_error(ArgumentError, /client_id/)
    end

    it "handles network errors gracefully" do
      allow_any_instance_of(Net::HTTP).to receive(:request).and_raise(Net::OpenTimeout)

      expect {
        oauth_client.exchange_code_for_token(code: "test_code")
      }.to raise_error(Attio::ConnectionError)
    end
  end
end
