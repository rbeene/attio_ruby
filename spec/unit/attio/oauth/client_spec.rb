# frozen_string_literal: true

RSpec.describe Attio::OAuth::Client do
  let(:client_id) { "test_client_id" }
  let(:client_secret) { "test_client_secret" }
  let(:redirect_uri) { "https://example.com/callback" }
  let(:client) do
    described_class.new(
      client_id: client_id,
      client_secret: client_secret,
      redirect_uri: redirect_uri
    )
  end

  describe "#initialize" do
    it "validates required parameters" do
      expect do
        described_class.new(client_id: nil, client_secret: "secret", redirect_uri: "uri")
      end.to raise_error(ArgumentError, "client_id is required")

      expect do
        described_class.new(client_id: "id", client_secret: nil, redirect_uri: "uri")
      end.to raise_error(ArgumentError, "client_secret is required")

      expect do
        described_class.new(client_id: "id", client_secret: "secret", redirect_uri: nil)
      end.to raise_error(ArgumentError, "redirect_uri is required")
    end

    it "validates redirect_uri format" do
      expect do
        described_class.new(client_id: "id", client_secret: "secret", redirect_uri: "not-a-url")
      end.to raise_error(ArgumentError, "redirect_uri must be a valid HTTP(S) URL")
    end
  end

  describe "#authorization_url" do
    context "when generating authorization URL" do
      let(:result) { client.authorization_url }

      it "returns a hash with URL and state" do
        expect(result).to be_a(Hash)
        expect(result).to have_key(:url)
        expect(result).to have_key(:state)
      end

      it "uses the correct OAuth endpoint" do
        expect(result[:url]).to start_with("https://app.attio.com/authorize")
      end

      it "includes the client ID" do
        expect(result[:url]).to include("client_id=#{client_id}")
      end

      it "includes the encoded redirect URI" do
        expect(result[:url]).to include("redirect_uri=#{CGI.escape(redirect_uri)}")
      end

      it "includes the response type" do
        expect(result[:url]).to include("response_type=code")
      end

      it "generates a state value" do
        expect(result[:state]).to be_a(String)
        expect(result[:state].length).to be > 20
      end
    end

    it "includes custom scopes" do
      result = client.authorization_url(scopes: ["record:read", "record:write"])
      expect(result[:url]).to include("scope=record%3Aread+record%3Awrite")
    end

    it "includes custom state" do
      custom_state = "custom_state_123"
      result = client.authorization_url(state: custom_state)
      expect(result[:state]).to eq(custom_state)
      expect(result[:url]).to include("state=#{custom_state}")
    end

    it "validates scopes" do
      expect do
        client.authorization_url(scopes: ["invalid:scope"])
      end.to raise_error(ArgumentError, /Invalid scopes/)
    end
  end

  describe "#exchange_code_for_token" do
    let(:code) { "auth_code_123" }
    let(:token_response) do
      {
        access_token: "access_token_123",
        refresh_token: "refresh_token_123",
        token_type: "Bearer",
        expires_in: 3600,
        scope: "record:read record:write"
      }
    end

    before do
      stub_request(:post, "https://api.attio.com/v2/oauth/token")
        .with(
          body: {
            grant_type: "authorization_code",
            code: code,
            redirect_uri: redirect_uri,
            client_id: client_id,
            client_secret: client_secret
          },
          headers: {"Accept" => "application/json"}
        )
        .to_return(
          status: 200,
          body: token_response.to_json,
          headers: {"Content-Type" => "application/json"}
        )
    end

    it "exchanges code for token" do
      result = client.exchange_code_for_token(code: code)
      expect(result).to be_a(Attio::OAuth::Token)
      expect(result.access_token).to eq("access_token_123")
      expect(result.refresh_token).to eq("refresh_token_123")
    end

    it "raises error without code" do
      expect do
        client.exchange_code_for_token(code: nil)
      end.to raise_error(ArgumentError, "Authorization code is required")
    end

    it "sends correct parameters" do
      client.exchange_code_for_token(code: code)
      expect(WebMock).to have_requested(:post, "https://api.attio.com/v2/oauth/token")
        .with(body: hash_including("grant_type" => "authorization_code", "code" => code))
    end
  end

  describe "#refresh_token" do
    let(:refresh_token) { "refresh_token_123" }
    let(:token_response) do
      {
        access_token: "new_access_token_123",
        refresh_token: "new_refresh_token_123",
        token_type: "Bearer",
        expires_in: 3600
      }
    end

    before do
      stub_request(:post, "https://api.attio.com/v2/oauth/token")
        .with(
          body: {
            grant_type: "refresh_token",
            refresh_token: refresh_token,
            client_id: client_id,
            client_secret: client_secret
          },
          headers: {"Accept" => "application/json"}
        )
        .to_return(
          status: 200,
          body: token_response.to_json,
          headers: {"Content-Type" => "application/json"}
        )
    end

    it "refreshes the token" do
      result = client.refresh_token(refresh_token)
      expect(result).to be_a(Attio::OAuth::Token)
      expect(result.access_token).to eq("new_access_token_123")
    end

    it "sends correct parameters" do
      client.refresh_token(refresh_token)
      expect(WebMock).to have_requested(:post, "https://api.attio.com/v2/oauth/token")
        .with(body: hash_including("grant_type" => "refresh_token"))
    end
  end

  describe "#revoke_token" do
    let(:token) { "access_token_123" }

    before do
      stub_request(:post, "https://api.attio.com/v2/oauth/revoke")
        .with(
          body: /token=#{token}/,
          headers: {"Content-Type" => "application/x-www-form-urlencoded"}
        )
        .to_return(status: 200, body: "")
    end

    it "revokes a token string" do
      result = client.revoke_token(token)
      expect(result).to be true
    end

    it "revokes a Token object" do
      token_obj = Attio::OAuth::Token.new(
        access_token: token,
        token_type: "Bearer",
        expires_in: 3600
      )
      result = client.revoke_token(token_obj)
      expect(result).to be true
    end

    it "returns false on error" do
      stub_request(:post, "https://api.attio.com/v2/oauth/revoke")
        .to_return(status: 400, body: "")

      result = client.revoke_token(token)
      expect(result).to be false
    end
  end

  describe "#introspect_token" do
    let(:token) { "access_token_123" }
    let(:introspection_response) do
      {
        active: true,
        scope: "record:read record:write",
        client_id: client_id,
        token_type: "Bearer",
        exp: 1234567890
      }
    end

    before do
      stub_request(:post, "https://api.attio.com/v2/oauth/introspect")
        .with(
          body: /token=#{token}/,
          headers: {"Content-Type" => "application/x-www-form-urlencoded"}
        )
        .to_return(
          status: 200,
          body: introspection_response.to_json,
          headers: {"Content-Type" => "application/json"}
        )
    end

    it "introspects a token" do
      result = client.introspect_token(token)
      expect(result).to be_a(Hash)
      expect(result[:active]).to be true
      expect(result[:scope]).to eq("record:read record:write")
    end
  end
end
