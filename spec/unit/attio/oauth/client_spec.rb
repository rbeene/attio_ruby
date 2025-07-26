# frozen_string_literal: true

RSpec.describe Attio::OAuth::Client do
  let(:client_id) { "test_client_id" }
  let(:client) do
    described_class.new(
      client_id: client_id,
      client_secret: client_secret,
      redirect_uri: redirect_uri
    )
  end
  let(:client_secret) { "test_client_secret" }
  let(:redirect_uri) { "https://example.com/callback" }
  let(:connection_manager) { instance_double(Attio::Util::ConnectionManager) }

  before do
    allow(Attio).to receive(:connection_manager).and_return(connection_manager)
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
        described_class.new(
          client_id: "id",
          client_secret: "secret",
          redirect_uri: "not-a-url"
        )
      end.to raise_error(ArgumentError, "redirect_uri must be a valid HTTP(S) URL")
    end
  end

  describe "#authorization_url" do
    describe "generating authorization URL" do
      let(:result) { client.authorization_url }

      it "returns a hash with URL and state" do
        expect(result).to be_a(Hash)
        expect(result).to have_key(:url)
        expect(result).to have_key(:state)
      end

      it "uses the correct OAuth endpoint" do
        expect(result[:url]).to include("https://app.attio.com/authorize")
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
        expect(result[:state]).not_to be_nil
      end
    end

    it "includes custom scopes" do
      result = client.authorization_url(scopes: %w[record:read record:write])

      expect(result[:url]).to include("scope=record%3Aread+record%3Awrite")
    end

    it "includes custom state" do
      custom_state = "custom_state_123"
      result = client.authorization_url(state: custom_state)

      expect(result[:url]).to include("state=#{custom_state}")
      expect(result[:state]).to eq(custom_state)
    end

    it "validates scopes" do
      expect do
        client.authorization_url(scopes: ["invalid:scope"])
      end.to raise_error(ArgumentError, /Invalid scopes/)
    end
  end

  describe "#exchange_code_for_token" do
    let(:auth_code) { "test_auth_code" }
    let(:response) do
      {
        status: 200,
        headers: {},
        body: JSON.generate({
          access_token: "access_123",
          refresh_token: "refresh_123",
          token_type: "Bearer",
          expires_in: 3600
        })
      }
    end

    it "exchanges code for token" do
      allow(connection_manager).to receive(:execute).and_return(response)

      token = client.exchange_code_for_token(code: auth_code)

      expect(token).to be_a(Attio::OAuth::Token)
      expect(token.access_token).to eq("access_123")
      expect(token.refresh_token).to eq("refresh_123")
    end

    it "sends correct parameters" do
      allow(connection_manager).to receive(:execute) do |request|
        params = URI.decode_www_form(request[:body]).to_h
        expect(params["grant_type"]).to eq("authorization_code")
        expect(params["code"]).to eq(auth_code)
        expect(params["client_id"]).to eq(client_id)
        expect(params["client_secret"]).to eq(client_secret)
        response
      end

      client.exchange_code_for_token(code: auth_code)
    end

    it "raises error without code" do
      expect do
        client.exchange_code_for_token(code: nil)
      end.to raise_error(ArgumentError, "Authorization code is required")
    end
  end

  describe "#refresh_token" do
    let(:refresh_token) { "refresh_123" }
    let(:response) do
      {
        status: 200,
        headers: {},
        body: JSON.generate({
          access_token: "new_access_123",
          refresh_token: "new_refresh_123",
          token_type: "Bearer",
          expires_in: 3600
        })
      }
    end

    it "refreshes the token" do
      allow(connection_manager).to receive(:execute).and_return(response)

      token = client.refresh_token(refresh_token)

      expect(token).to be_a(Attio::OAuth::Token)
      expect(token.access_token).to eq("new_access_123")
    end

    it "sends correct parameters" do
      allow(connection_manager).to receive(:execute) do |request|
        params = URI.decode_www_form(request[:body]).to_h
        expect(params["grant_type"]).to eq("refresh_token")
        expect(params["refresh_token"]).to eq(refresh_token)
        response
      end

      client.refresh_token(refresh_token)
    end
  end

  describe "#revoke_token" do
    let(:token) { "access_123" }

    it "revokes a token string" do
      allow(connection_manager).to receive(:execute).and_return({status: 200})

      result = client.revoke_token(token)

      expect(connection_manager).to have_received(:execute)
      expect(result).to be true
    end

    it "revokes a Token object" do
      token_obj = Attio::OAuth::Token.new(access_token: "access_123")
      allow(connection_manager).to receive(:execute).and_return({status: 200})

      result = client.revoke_token(token_obj)
      expect(result).to be true
    end

    it "returns false on error" do
      allow(connection_manager).to receive(:execute).and_raise(Attio::Error)

      result = client.revoke_token(token)
      expect(result).to be false
    end
  end

  describe "#introspect_token" do
    let(:token) { "access_123" }
    let(:response) do
      {
        status: 200,
        headers: {},
        body: JSON.generate({
          active: true,
          scope: "record:read record:write",
          client_id: client_id,
          exp: 1234567890
        })
      }
    end

    it "introspects a token" do
      allow(connection_manager).to receive(:execute).and_return(response)

      result = client.introspect_token(token)

      expect(result[:active]).to be true
      expect(result[:scope]).to eq("record:read record:write")
    end
  end
end
