# frozen_string_literal: true

require "spec_helper"

RSpec.describe Attio::OAuth::Token do
  let(:token_attributes) do
    {
      access_token: "access_token_123",
      refresh_token: "refresh_token_456",
      token_type: "Bearer",
      expires_in: 3600,
      scope: "record:read record:write"
    }
  end

  describe "#initialize" do
    it "sets attributes correctly" do
      token = described_class.new(token_attributes)

      expect(token.access_token).to eq("access_token_123")
      expect(token.refresh_token).to eq("refresh_token_456")
      expect(token.token_type).to eq("Bearer")
      expect(token.expires_in).to eq(3600)
      expect(token.scope).to eq(["record:read", "record:write"])
      expect(token.created_at).to be_a(Time)
      expect(token.expires_at).to be_a(Time)
    end

    it "handles string keys" do
      string_attrs = {
        "access_token" => "token_789",
        "refresh_token" => "refresh_789",
        "token_type" => "Bearer",
        "expires_in" => "7200",
        "scope" => "record:read"
      }

      token = described_class.new(string_attrs)
      expect(token.access_token).to eq("token_789")
      expect(token.expires_in).to eq(7200)
    end

    it "defaults token_type to Bearer" do
      token = described_class.new(access_token: "token_123")
      expect(token.token_type).to eq("Bearer")
    end

    it "handles scope as array" do
      token = described_class.new(
        access_token: "token_123",
        scope: ["record:read", "record:write"]
      )
      expect(token.scope).to eq(["record:read", "record:write"])
    end

    it "handles nil scope" do
      token = described_class.new(
        access_token: "token_123",
        scope: nil
      )
      expect(token.scope).to be_nil
    end

    it "handles non-string/array scope" do
      token = described_class.new(
        access_token: "token_123",
        scope: 123
      )
      expect(token.scope).to eq([])
    end

    it "calculates expiration time" do
      created_at = Time.parse("2023-01-15T10:00:00Z")
      token = described_class.new(
        access_token: "token_123",
        created_at: created_at,
        expires_in: 3600
      )
      expect(token.expires_at).to eq(created_at + 3600)
    end

    it "handles nil expires_in" do
      token = described_class.new(access_token: "token_123")
      expect(token.expires_at).to be_nil
    end

    it "validates access token is required" do
      expect {
        described_class.new({})
      }.to raise_error(
        Attio::OAuth::Token::InvalidTokenError,
        "Access token is required"
      )
    end

    it "validates access token is not empty" do
      expect {
        described_class.new(access_token: "")
      }.to raise_error(
        Attio::OAuth::Token::InvalidTokenError,
        "Access token is required"
      )
    end

    it "validates token type" do
      expect {
        described_class.new(access_token: "token_123", token_type: "Invalid")
      }.to raise_error(
        Attio::OAuth::Token::InvalidTokenError,
        "Invalid token type"
      )
    end

    it "accepts lowercase bearer token type" do
      token = described_class.new(
        access_token: "token_123",
        token_type: "bearer"
      )
      expect(token.token_type).to eq("bearer")
    end

    it "stores OAuth client reference" do
      client = double("OAuth::Client")
      token = described_class.new(
        access_token: "token_123",
        client: client
      )
      expect(token.client).to eq(client)
    end
  end

  describe "#expired?" do
    it "returns false when no expiration" do
      token = described_class.new(access_token: "token_123")
      expect(token.expired?).to be false
    end

    it "returns false when not expired" do
      token = described_class.new(
        access_token: "token_123",
        expires_in: 3600
      )
      expect(token.expired?).to be false
    end

    it "returns true when expired" do
      token = described_class.new(
        access_token: "token_123",
        created_at: Time.now.utc - 7200,
        expires_in: 3600
      )
      expect(token.expired?).to be true
    end
  end

  describe "#expires_soon?" do
    it "returns false when no expiration" do
      token = described_class.new(access_token: "token_123")
      expect(token.expires_soon?).to be false
    end

    it "returns false when not expiring soon" do
      token = described_class.new(
        access_token: "token_123",
        expires_in: 3600
      )
      expect(token.expires_soon?).to be false
    end

    it "returns true when expiring within default threshold" do
      token = described_class.new(
        access_token: "token_123",
        created_at: Time.now.utc - 3400,
        expires_in: 3600
      )
      expect(token.expires_soon?).to be true
    end

    it "accepts custom threshold" do
      token = described_class.new(
        access_token: "token_123",
        created_at: Time.now.utc - 3000,
        expires_in: 3600
      )
      # Token expires in 600 seconds (3600 - 3000)
      expect(token.expires_soon?(500)).to be false
      expect(token.expires_soon?(700)).to be true
    end
  end

  describe "#refresh!" do
    let(:client) { double("OAuth::Client") }
    let(:token) do
      described_class.new(
        access_token: "old_token",
        refresh_token: "refresh_123",
        client: client
      )
    end

    it "refreshes the token" do
      new_token = described_class.new(
        access_token: "new_token",
        refresh_token: "new_refresh",
        expires_in: 7200
      )

      allow(client).to receive(:refresh_token).with("refresh_123").and_return(new_token)

      token.refresh!
      expect(token.access_token).to eq("new_token")
      expect(token.refresh_token).to eq("new_refresh")
      expect(token.expires_in).to eq(7200)
    end

    it "raises error when no refresh token" do
      token_without_refresh = described_class.new(access_token: "token_123")

      expect {
        token_without_refresh.refresh!
      }.to raise_error(
        Attio::OAuth::Token::InvalidTokenError,
        "No refresh token available"
      )
    end

    it "raises error when no client" do
      token_without_client = described_class.new(
        access_token: "token_123",
        refresh_token: "refresh_123"
      )

      expect {
        token_without_client.refresh!
      }.to raise_error(
        Attio::OAuth::Token::InvalidTokenError,
        "No OAuth client configured"
      )
    end

    it "preserves refresh token if new token doesn't include one" do
      new_token = described_class.new(
        access_token: "new_token",
        expires_in: 7200
      )

      allow(client).to receive(:refresh_token).and_return(new_token)

      token.refresh!
      expect(token.refresh_token).to eq("refresh_123") # Original preserved
    end
  end

  describe "#revoke!" do
    let(:client) { double("OAuth::Client") }
    let(:token) do
      described_class.new(
        access_token: "token_123",
        refresh_token: "refresh_123",
        client: client
      )
    end

    it "revokes the token" do
      allow(client).to receive(:revoke_token).with(token)

      result = token.revoke!
      expect(result).to be true
      expect(token.access_token).to be_nil
      expect(token.refresh_token).to be_nil
    end

    it "raises error when no client" do
      token_without_client = described_class.new(access_token: "token_123")

      expect {
        token_without_client.revoke!
      }.to raise_error(
        Attio::OAuth::Token::InvalidTokenError,
        "No OAuth client configured"
      )
    end
  end

  describe "#to_h" do
    it "includes all token fields" do
      created_at = Time.parse("2023-01-15T10:00:00Z")
      token = described_class.new(
        access_token: "token_123",
        refresh_token: "refresh_123",
        token_type: "Bearer",
        expires_in: 3600,
        scope: "record:read",
        created_at: created_at
      )

      hash = token.to_h
      expect(hash).to include(
        access_token: "token_123",
        refresh_token: "refresh_123",
        token_type: "Bearer",
        expires_in: 3600,
        expires_at: "2023-01-15T11:00:00Z",
        scope: ["record:read"],
        created_at: "2023-01-15T10:00:00Z"
      )
    end

    it "compacts nil values" do
      token = described_class.new(access_token: "token_123")
      hash = token.to_h

      expect(hash).to have_key(:access_token)
      expect(hash).to have_key(:token_type)
      expect(hash).not_to have_key(:refresh_token)
      expect(hash).not_to have_key(:expires_at)
    end
  end

  describe "#to_json" do
    it "converts to JSON string" do
      token = described_class.new(token_attributes)
      json = token.to_json

      parsed = JSON.parse(json)
      expect(parsed["access_token"]).to eq("access_token_123")
      expect(parsed["token_type"]).to eq("Bearer")
    end

    it "accepts JSON options" do
      token = described_class.new(access_token: "token_123")
      # Just verify it accepts options without error
      expect { token.to_json(pretty: true) }.not_to raise_error
    end
  end

  describe "#inspect" do
    it "masks access token" do
      token = described_class.new(
        access_token: "secret_token_12345",
        scope: "record:read"
      )

      inspection = token.inspect
      expect(inspection).to include("token=***2345")
      expect(inspection).to include("scope=record:read")
      expect(inspection).not_to include("secret_token")
    end

    it "handles nil access token" do
      # Use a mock to avoid validation
      token = described_class.allocate
      token.instance_variable_set(:@access_token, nil)
      token.instance_variable_set(:@scope, [])

      expect(token.inspect).to include("token=nil")
    end

    it "includes expiration info" do
      token = described_class.new(
        access_token: "token_123",
        expires_in: 3600
      )

      expect(token.inspect).to match(/expires_at=\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z/)
    end
  end

  describe "#authorization_header" do
    it "returns formatted authorization header" do
      token = described_class.new(token_attributes)
      expect(token.authorization_header).to eq("Bearer access_token_123")
    end

    it "uses token type from token" do
      token = described_class.new(
        access_token: "token_123",
        token_type: "bearer"
      )
      expect(token.authorization_header).to eq("bearer token_123")
    end
  end

  describe "#has_scope?" do
    let(:token) do
      described_class.new(
        access_token: "token_123",
        scope: "record:read record:write user:read"
      )
    end

    it "returns true for existing scope" do
      expect(token.has_scope?("record:read")).to be true
      expect(token.has_scope?("record:write")).to be true
    end

    it "returns false for missing scope" do
      expect(token.has_scope?("record:delete")).to be false
    end

    it "handles symbol input" do
      expect(token.has_scope?(:"record:read")).to be true
    end

    it "handles nil scope" do
      token_nil_scope = described_class.new(
        access_token: "token_123",
        scope: nil
      )
      expect { token_nil_scope.has_scope?("any") }.to raise_error(NoMethodError)
    end
  end

  describe "#save" do
    it "returns self by default" do
      token = described_class.new(access_token: "token_123")
      expect(token.save).to eq(token)
    end
  end

  describe ".load" do
    it "returns nil by default" do
      expect(described_class.load).to be_nil
    end

    it "accepts identifier parameter" do
      expect(described_class.load("user_123")).to be_nil
    end
  end

  describe "edge cases" do
    it "handles empty attributes hash" do
      expect {
        described_class.new(nil)
      }.to raise_error(Attio::OAuth::Token::InvalidTokenError)
    end

    it "converts integer scope to string array" do
      token = described_class.new(
        access_token: "token_123",
        scope: [:read, :write]
      )
      expect(token.scope).to eq(["read", "write"])
    end

    it "handles expires_in as string" do
      token = described_class.new(
        access_token: "token_123",
        expires_in: "3600"
      )
      expect(token.expires_in).to eq(3600)
    end
  end
end
