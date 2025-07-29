# frozen_string_literal: true

require "spec_helper"

RSpec.describe Attio::OAuth::ScopeValidator do
  describe ".validate" do
    it "returns valid scopes as an array" do
      result = described_class.validate(["record:read", "record:write"])
      expect(result).to eq(["record:read", "record:write"])
    end

    it "accepts a single scope string" do
      result = described_class.validate("record:read")
      expect(result).to eq(["record:read"])
    end

    it "converts symbol scopes to strings" do
      result = described_class.validate([:"record:read", :"record:write"])
      expect(result).to eq(["record:read", "record:write"])
    end

    it "raises InvalidScopeError for invalid scopes" do
      expect {
        described_class.validate(["record:read", "invalid:scope"])
      }.to raise_error(
        Attio::OAuth::ScopeValidator::InvalidScopeError,
        "Invalid scopes: invalid:scope"
      )
    end

    it "raises InvalidScopeError for multiple invalid scopes" do
      expect {
        described_class.validate(["invalid:one", "record:read", "invalid:two"])
      }.to raise_error(
        Attio::OAuth::ScopeValidator::InvalidScopeError,
        "Invalid scopes: invalid:one, invalid:two"
      )
    end
  end

  describe ".validate!" do
    it "returns true for valid scopes" do
      expect(described_class.validate!(["record:read"])).to be true
    end

    it "raises InvalidScopeError for invalid scopes" do
      expect {
        described_class.validate!("invalid:scope")
      }.to raise_error(Attio::OAuth::ScopeValidator::InvalidScopeError)
    end
  end

  describe ".valid?" do
    it "returns true for valid scopes" do
      expect(described_class.valid?("record:read")).to be true
      expect(described_class.valid?("object:write")).to be true
      expect(described_class.valid?("user:read")).to be true
    end

    it "returns false for invalid scopes" do
      expect(described_class.valid?("invalid:scope")).to be false
      expect(described_class.valid?("record:delete")).to be false
    end

    it "handles symbol input" do
      expect(described_class.valid?(:"record:read")).to be true
    end
  end

  describe ".description" do
    it "returns description for valid scopes" do
      expect(described_class.description("record:read")).to eq("Read access to records")
      expect(described_class.description("webhook:write")).to eq("Write access to webhooks (includes read)")
    end

    it "returns nil for invalid scopes" do
      expect(described_class.description("invalid:scope")).to be_nil
    end

    it "handles symbol input" do
      expect(described_class.description(:"record:read")).to eq("Read access to records")
    end
  end

  describe ".includes?" do
    context "with direct scope match" do
      it "returns true when scope is directly included" do
        expect(described_class.includes?(["record:read", "object:read"], "record:read")).to be true
      end

      it "returns false when scope is not included" do
        expect(described_class.includes?(["record:read"], "object:read")).to be false
      end
    end

    context "with implied scopes" do
      it "returns true when write scope implies read scope" do
        expect(described_class.includes?(["record:write"], "record:read")).to be true
        expect(described_class.includes?(["object:write"], "object:read")).to be true
      end

      it "returns false when read scope doesn't imply write" do
        expect(described_class.includes?(["record:read"], "record:write")).to be false
      end
    end

    it "handles single scope string" do
      expect(described_class.includes?("record:write", "record:read")).to be true
    end

    it "handles symbol input" do
      expect(described_class.includes?([:"record:write"], :"record:read")).to be true
    end
  end

  describe ".expand" do
    it "expands write scopes to include read scopes" do
      result = described_class.expand(["record:write"])
      expect(result).to contain_exactly("record:read", "record:write")
    end

    it "expands multiple write scopes" do
      result = described_class.expand(["record:write", "object:write"])
      expect(result).to contain_exactly(
        "record:read", "record:write",
        "object:read", "object:write"
      )
    end

    it "returns sorted results" do
      result = described_class.expand(["webhook:write", "attribute:write"])
      expect(result).to eq([
        "attribute:read", "attribute:write",
        "webhook:read", "webhook:write"
      ])
    end

    it "handles scopes without implications" do
      result = described_class.expand(["user:read"])
      expect(result).to eq(["user:read"])
    end

    it "handles single scope string" do
      result = described_class.expand("record:write")
      expect(result).to contain_exactly("record:read", "record:write")
    end
  end

  describe ".minimize" do
    it "removes redundant read scopes when write scope exists" do
      result = described_class.minimize(["record:read", "record:write"])
      expect(result).to eq(["record:write"])
    end

    it "removes multiple redundant read scopes" do
      result = described_class.minimize([
        "record:read", "record:write",
        "object:read", "object:write"
      ])
      expect(result).to contain_exactly("object:write", "record:write")
    end

    it "keeps read scopes without corresponding write scopes" do
      result = described_class.minimize(["record:read", "object:write"])
      expect(result).to contain_exactly("object:write", "record:read")
    end

    it "returns sorted results" do
      result = described_class.minimize(["webhook:write", "attribute:write", "user:read"])
      expect(result).to eq(["attribute:write", "user:read", "webhook:write"])
    end

    it "handles empty array" do
      expect(described_class.minimize([])).to eq([])
    end
  end

  describe ".group_by_resource" do
    it "groups scopes by resource type" do
      result = described_class.group_by_resource([
        "record:read", "record:write",
        "object:read",
        "webhook:write"
      ])

      expect(result).to eq({
        "record" => ["record:read", "record:write"],
        "object" => ["object:read"],
        "webhook" => ["webhook:write"]
      })
    end

    it "handles single scope" do
      result = described_class.group_by_resource("record:read")
      expect(result).to eq({"record" => ["record:read"]})
    end

    it "handles empty array" do
      expect(described_class.group_by_resource([])).to eq({})
    end
  end

  describe ".sufficient_for?" do
    it "returns true when exact scope exists" do
      expect(
        described_class.sufficient_for?(["record:read"], resource: "record", operation: "read")
      ).to be true
    end

    it "returns true when write scope covers read operation" do
      expect(
        described_class.sufficient_for?(["record:write"], resource: "record", operation: "read")
      ).to be true
    end

    it "returns false when scope is insufficient" do
      expect(
        described_class.sufficient_for?(["record:read"], resource: "record", operation: "write")
      ).to be false
    end

    it "returns false for different resource" do
      expect(
        described_class.sufficient_for?(["record:write"], resource: "object", operation: "read")
      ).to be false
    end
  end

  describe "VALID_SCOPES" do
    it "includes all defined scopes" do
      expect(described_class::VALID_SCOPES).to include(
        "record:read", "record:write",
        "object:read", "object:write",
        "list:read", "list:write",
        "webhook:read", "webhook:write",
        "user:read",
        "note:read", "note:write",
        "attribute:read", "attribute:write",
        "comment:read", "comment:write",
        "task:read", "task:write"
      )
    end

    it "is frozen" do
      expect(described_class::VALID_SCOPES).to be_frozen
    end
  end

  describe "SCOPE_HIERARCHY" do
    it "defines write->read relationships" do
      expect(described_class::SCOPE_HIERARCHY["record:write"]).to eq(["record:read"])
      expect(described_class::SCOPE_HIERARCHY["object:write"]).to eq(["object:read"])
    end

    it "doesn't define relationships for read scopes" do
      expect(described_class::SCOPE_HIERARCHY["record:read"]).to be_nil
    end

    it "is frozen" do
      expect(described_class::SCOPE_HIERARCHY).to be_frozen
    end
  end
end
