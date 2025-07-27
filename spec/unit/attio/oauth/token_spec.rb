# frozen_string_literal: true

require "spec_helper"

RSpec.describe Attio::OAuth::Token do
  let(:valid_attributes) do
    {
      access_token: "test_access_token_123",
      refresh_token: "test_refresh_token_456",
      token_type: "Bearer",
      expires_in: 3600,
      scope: "record:read record:write",
      created_at: Time.now.utc
    }
  end

  describe "#initialize" do
    it "creates a token with valid attributes" do
      token = described_class.new(valid_attributes)
      expect(token.access_token).to eq("test_access_token_123")
      expect(token.refresh_token).to eq("test_refresh_token_456")
      expect(token.token_type).to eq("Bearer")
      expect(token.expires_in).to eq(3600)
      expect(token.scope).to eq(["record:read", "record:write"])
    end

    it "calculates expires_at based on expires_in and created_at" do
      created_at = Time.now.utc
      token = described_class.new(valid_attributes.merge(created_at: created_at))
      expect(token.expires_at).to eq(created_at + 3600)
    end

    it "defaults token_type to Bearer" do
      token = described_class.new(valid_attributes.except(:token_type))
      expect(token.token_type).to eq("Bearer")
    end

    it "defaults created_at to current time" do
      freeze_time = Time.now.utc
      allow(Time).to receive(:now).and_return(freeze_time)
      token = described_class.new(valid_attributes.except(:created_at))
      expect(token.created_at).to eq(freeze_time)
    end

    it "parses scope from string" do
      token = described_class.new(valid_attributes)
      expect(token.scope).to eq(["record:read", "record:write"])
    end

    it "parses scope from array" do
      token = described_class.new(valid_attributes.merge(scope: ["user:read", "user:write"]))
      expect(token.scope).to eq(["user:read", "user:write"])
    end

    it "handles nil scope" do
      token = described_class.new(valid_attributes.merge(scope: nil))
      expect(token.scope).to eq([])
    end

    it "normalizes attribute keys to symbols" do
      token = described_class.new({
        "access_token" => "test_token",
        "refresh_token" => "refresh_token",
        "expires_in" => "3600"
      })
      expect(token.access_token).to eq("test_token")
      expect(token.refresh_token).to eq("refresh_token")
      expect(token.expires_in).to eq(3600)
    end

    it "raises error for missing access token" do
      expect {
        described_class.new(valid_attributes.except(:access_token))
      }.to raise_error(Attio::OAuth::Token::InvalidTokenError, "Access token is required")
    end

    it "raises error for empty access token" do
      expect {
        described_class.new(valid_attributes.merge(access_token: ""))
      }.to raise_error(Attio::OAuth::Token::InvalidTokenError, "Access token is required")
    end

    it "raises error for invalid token type" do
      expect {
        described_class.new(valid_attributes.merge(token_type: "Invalid"))
      }.to raise_error(Attio::OAuth::Token::InvalidTokenError, "Invalid token type")
    end

    it "accepts lowercase bearer token type" do
      token = described_class.new(valid_attributes.merge(token_type: "bearer"))
      expect(token.token_type).to eq("bearer")
    end
  end

  describe "#expired?" do
    it "returns false when expires_at is nil" do
      token = described_class.new(valid_attributes.merge(expires_in: nil))
      expect(token.expired?).to be false
    end

    it "returns false when token has not expired" do
      token = described_class.new(valid_attributes.merge(expires_in: 3600))
      expect(token.expired?).to be false
    end

    it "returns true when token has expired" do
      created_at = Time.now.utc - 7200 # 2 hours ago
      token = described_class.new(valid_attributes.merge(
        created_at: created_at,
        expires_in: 3600 # expires after 1 hour
      ))
      expect(token.expired?).to be true
    end
  end

  describe "#expires_soon?" do
    it "returns false when expires_at is nil" do
      token = described_class.new(valid_attributes.merge(expires_in: nil))
      expect(token.expires_soon?).to be false
    end

    it "returns false when expiration is far away" do
      token = described_class.new(valid_attributes.merge(expires_in: 3600))
      expect(token.expires_soon?).to be false
    end

    it "returns true when token expires within default threshold (5 minutes)" do
      created_at = Time.now.utc - 3400 # Will expire in 200 seconds
      token = described_class.new(valid_attributes.merge(
        created_at: created_at,
        expires_in: 3600
      ))
      expect(token.expires_soon?).to be true
    end

    it "returns true when token expires within custom threshold" do
      created_at = Time.now.utc - 3000 # Will expire in 600 seconds
      token = described_class.new(valid_attributes.merge(
        created_at: created_at,
        expires_in: 3600
      ))
      expect(token.expires_soon?(700)).to be true
      expect(token.expires_soon?(500)).to be false
    end
  end

  describe "#refresh!" do
    let(:token) { described_class.new(valid_attributes) }
    let(:client) { instance_double(Attio::OAuth::Client) }
    let(:new_token) do
      described_class.new(valid_attributes.merge(
        access_token: "new_access_token",
        expires_in: 7200
      ))
    end

    before do
      token.instance_variable_set(:@client, client)
    end

    it "refreshes the token using the client" do
      allow(client).to receive(:refresh_token).with("test_refresh_token_456").and_return(new_token)

      result = token.refresh!
      expect(result).to eq(token)
      expect(token.access_token).to eq("new_access_token")
      expect(token.expires_in).to eq(7200)
    end

    it "raises error when no refresh token available" do
      token_without_refresh = described_class.new(valid_attributes.merge(refresh_token: nil))
      token_without_refresh.instance_variable_set(:@client, client)

      expect {
        token_without_refresh.refresh!
      }.to raise_error(Attio::OAuth::Token::InvalidTokenError, "No refresh token available")
    end

    it "raises error when no client configured" do
      token.instance_variable_set(:@client, nil)

      expect {
        token.refresh!
      }.to raise_error(Attio::OAuth::Token::InvalidTokenError, "No OAuth client configured")
    end
  end

  describe "#revoke!" do
    let(:token) { described_class.new(valid_attributes) }
    let(:client) { instance_double(Attio::OAuth::Client) }

    before do
      token.instance_variable_set(:@client, client)
    end

    it "revokes the token using the client" do
      allow(client).to receive(:revoke_token).with(token).and_return(true)

      result = token.revoke!
      expect(result).to be true
      expect(token.access_token).to be_nil
      expect(token.refresh_token).to be_nil
    end

    it "raises error when no client configured" do
      token.instance_variable_set(:@client, nil)

      expect {
        token.revoke!
      }.to raise_error(Attio::OAuth::Token::InvalidTokenError, "No OAuth client configured")
    end
  end

  describe "#to_h" do
    it "returns a hash representation" do
      token = described_class.new(valid_attributes)
      hash = token.to_h

      expect(hash).to include(
        access_token: "test_access_token_123",
        refresh_token: "test_refresh_token_456",
        token_type: "Bearer",
        expires_in: 3600,
        scope: ["record:read", "record:write"]
      )
      expect(hash[:expires_at]).to match(/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z/)
      expect(hash[:created_at]).to match(/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z/)
    end

    it "excludes nil values" do
      token = described_class.new(valid_attributes.merge(refresh_token: nil, expires_in: nil))
      hash = token.to_h

      expect(hash).not_to have_key(:refresh_token)
      expect(hash).not_to have_key(:expires_in)
      expect(hash).not_to have_key(:expires_at)
    end
  end

  describe "#to_json" do
    it "returns JSON representation" do
      token = described_class.new(valid_attributes)
      json = token.to_json
      parsed = JSON.parse(json)

      expect(parsed["access_token"]).to eq("test_access_token_123")
      expect(parsed["refresh_token"]).to eq("test_refresh_token_456")
      expect(parsed["token_type"]).to eq("Bearer")
      expect(parsed["expires_in"]).to eq(3600)
      expect(parsed["scope"]).to eq(["record:read", "record:write"])
    end

    it "accepts JSON generation options" do
      token = described_class.new(valid_attributes)
      json = token.to_json(indent: "  ")

      expect(json).to include("  \"access_token\"")
    end
  end

  describe "#inspect" do
    it "returns a redacted string representation" do
      token = described_class.new(valid_attributes)
      inspection = token.inspect

      expect(inspection).to include("#<Attio::OAuth::Token:")
      expect(inspection).to include("token=***_123")
      expect(inspection).to include("scope=record:read record:write")
      expect(inspection).not_to include("test_access_token")
    end

    it "handles nil access token" do
      token = described_class.new(access_token: "a", token_type: "Bearer")
      token.instance_variable_set(:@access_token, nil)

      expect(token.inspect).to include("token=nil")
    end

    it "handles short access tokens" do
      token = described_class.new(valid_attributes.merge(access_token: "abc"))

      expect(token.inspect).to include("token=***abc")
    end
  end

  describe "#authorization_header" do
    it "returns the authorization header value" do
      token = described_class.new(valid_attributes)
      expect(token.authorization_header).to eq("Bearer test_access_token_123")
    end

    it "uses the configured token type" do
      token = described_class.new(valid_attributes.merge(token_type: "bearer"))
      expect(token.authorization_header).to eq("bearer test_access_token_123")
    end
  end

  describe "#has_scope?" do
    let(:token) { described_class.new(valid_attributes) }

    it "returns true for existing scope" do
      expect(token.has_scope?("record:read")).to be true
      expect(token.has_scope?("record:write")).to be true
    end

    it "returns false for non-existing scope" do
      expect(token.has_scope?("user:read")).to be false
    end

    it "handles symbol input" do
      expect(token.has_scope?(:record_read)).to be false
      expect(token.has_scope?(:"record:read")).to be true
    end
  end

  describe "#save" do
    it "returns self" do
      token = described_class.new(valid_attributes)
      expect(token.save).to eq(token)
    end
  end

  describe ".load" do
    it "returns nil by default" do
      expect(described_class.load).to be_nil
    end

    it "accepts an identifier parameter" do
      expect(described_class.load("test_id")).to be_nil
    end
  end

  describe "private methods" do
    describe "#update_from" do
      it "updates token attributes from another token" do
        token = described_class.new(valid_attributes)
        new_token = described_class.new(valid_attributes.merge(
          access_token: "new_token",
          expires_in: 7200,
          scope: "user:read"
        ))

        token.send(:update_from, new_token)

        expect(token.access_token).to eq("new_token")
        expect(token.refresh_token).to eq("test_refresh_token_456")
        expect(token.expires_in).to eq(7200)
        expect(token.scope).to eq(["user:read"])
      end

      it "preserves refresh token if new token doesn't have one" do
        token = described_class.new(valid_attributes)
        new_token = described_class.new(valid_attributes.merge(
          refresh_token: nil,
          access_token: "new_token"
        ))

        token.send(:update_from, new_token)

        expect(token.refresh_token).to eq("test_refresh_token_456")
      end
    end
  end
end
