# frozen_string_literal: true

require "spec_helper"

RSpec.describe Attio::OAuth::ScopeValidator do
  describe "SCOPE_DEFINITIONS" do
    it "includes all expected scopes" do
      expect(described_class::SCOPE_DEFINITIONS).to include(
        "record:read" => "Read access to records",
        "record:write" => "Write access to records (includes read)",
        "object:read" => "Read access to objects and their configuration",
        "object:write" => "Write access to objects (includes read)",
        "list:read" => "Read access to lists and list entries",
        "list:write" => "Write access to lists (includes read)",
        "webhook:read" => "Read access to webhooks",
        "webhook:write" => "Write access to webhooks (includes read)",
        "user:read" => "Read access to workspace members",
        "note:read" => "Read access to notes",
        "note:write" => "Write access to notes (includes read)",
        "attribute:read" => "Read access to attributes",
        "attribute:write" => "Write access to attributes (includes read)",
        "comment:read" => "Read access to comments",
        "comment:write" => "Write access to comments (includes read)",
        "task:read" => "Read access to tasks",
        "task:write" => "Write access to tasks (includes read)"
      )
    end

    it "is frozen" do
      expect(described_class::SCOPE_DEFINITIONS).to be_frozen
    end
  end

  describe "VALID_SCOPES" do
    it "contains all scope keys" do
      expect(described_class::VALID_SCOPES).to match_array(described_class::SCOPE_DEFINITIONS.keys)
    end

    it "is frozen" do
      expect(described_class::VALID_SCOPES).to be_frozen
    end
  end

  describe "SCOPE_HIERARCHY" do
    it "defines write scopes that include read scopes" do
      expect(described_class::SCOPE_HIERARCHY).to eq(
        "record:write" => ["record:read"],
        "object:write" => ["object:read"],
        "list:write" => ["list:read"],
        "webhook:write" => ["webhook:read"],
        "note:write" => ["note:read"],
        "attribute:write" => ["attribute:read"],
        "comment:write" => ["comment:read"],
        "task:write" => ["task:read"]
      )
    end

    it "is frozen" do
      expect(described_class::SCOPE_HIERARCHY).to be_frozen
    end
  end

  describe ".validate" do
    context "with valid scopes" do
      it "returns the scopes as an array of strings" do
        result = described_class.validate(["record:read", "object:write"])
        expect(result).to eq(["record:read", "object:write"])
      end

      it "handles a single scope string" do
        result = described_class.validate("record:read")
        expect(result).to eq(["record:read"])
      end

      it "handles symbol scopes" do
        result = described_class.validate([:"record:read", :"object:write"])
        expect(result).to eq(["record:read", "object:write"])
      end

      it "handles empty array" do
        result = described_class.validate([])
        expect(result).to eq([])
      end
    end

    context "with invalid scopes" do
      it "raises InvalidScopeError for unknown scopes" do
        expect {
          described_class.validate(["record:read", "invalid:scope"])
        }.to raise_error(
          Attio::OAuth::ScopeValidator::InvalidScopeError,
          "Invalid scopes: invalid:scope"
        )
      end

      it "raises InvalidScopeError for multiple invalid scopes" do
        expect {
          described_class.validate(["bad:scope", "another:bad", "record:read"])
        }.to raise_error(
          Attio::OAuth::ScopeValidator::InvalidScopeError,
          "Invalid scopes: bad:scope, another:bad"
        )
      end
    end
  end

  describe ".validate!" do
    it "returns true for valid scopes" do
      expect(described_class.validate!(["record:read"])).to be true
    end

    it "raises error for invalid scopes" do
      expect {
        described_class.validate!(["invalid:scope"])
      }.to raise_error(Attio::OAuth::ScopeValidator::InvalidScopeError)
    end
  end

  describe ".valid?" do
    it "returns true for valid scopes" do
      expect(described_class.valid?("record:read")).to be true
      expect(described_class.valid?("object:write")).to be true
    end

    it "returns false for invalid scopes" do
      expect(described_class.valid?("invalid:scope")).to be false
      expect(described_class.valid?("")).to be false
    end

    it "handles symbols" do
      expect(described_class.valid?(:record_read)).to be false # wrong format
      expect(described_class.valid?(:"record:read")).to be true
    end
  end

  describe ".description" do
    it "returns the description for a valid scope" do
      expect(described_class.description("record:read")).to eq("Read access to records")
      expect(described_class.description("webhook:write")).to eq("Write access to webhooks (includes read)")
    end

    it "returns nil for invalid scopes" do
      expect(described_class.description("invalid:scope")).to be_nil
    end

    it "handles symbols" do
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
        expect(described_class.includes?(["object:write", "list:write"], "object:read")).to be true
      end

      it "returns false when read scope doesn't imply write scope" do
        expect(described_class.includes?(["record:read"], "record:write")).to be false
      end
    end

    context "with different input formats" do
      it "handles single scope string" do
        expect(described_class.includes?("record:write", "record:read")).to be true
      end

      it "handles symbols" do
        expect(described_class.includes?([:"record:write"], :"record:read")).to be true
      end
    end
  end

  describe ".expand" do
    it "includes implied scopes for write permissions" do
      result = described_class.expand(["record:write"])
      expect(result).to contain_exactly("record:write", "record:read")
    end

    it "handles multiple write scopes" do
      result = described_class.expand(["record:write", "object:write"])
      expect(result).to contain_exactly("record:write", "record:read", "object:write", "object:read")
    end

    it "doesn't duplicate scopes" do
      result = described_class.expand(["record:write", "record:read"])
      expect(result).to contain_exactly("record:write", "record:read")
    end

    it "preserves read-only scopes" do
      result = described_class.expand(["user:read"])
      expect(result).to contain_exactly("user:read")
    end

    it "returns sorted results" do
      result = described_class.expand(["webhook:write", "attribute:write"])
      expect(result).to eq(["attribute:read", "attribute:write", "webhook:read", "webhook:write"])
    end
  end

  describe ".minimize" do
    it "removes redundant read scopes when write scope is present" do
      result = described_class.minimize(["record:write", "record:read"])
      expect(result).to eq(["record:write"])
    end

    it "handles multiple redundant scopes" do
      result = described_class.minimize(["record:write", "record:read", "object:write", "object:read"])
      expect(result).to contain_exactly("record:write", "object:write")
    end

    it "preserves non-redundant scopes" do
      result = described_class.minimize(["record:write", "object:read"])
      expect(result).to contain_exactly("record:write", "object:read")
    end

    it "handles read-only scopes" do
      result = described_class.minimize(["record:read", "object:read"])
      expect(result).to contain_exactly("record:read", "object:read")
    end

    it "returns sorted results" do
      result = described_class.minimize(["webhook:write", "webhook:read", "attribute:write"])
      expect(result).to eq(["attribute:write", "webhook:write"])
    end
  end

  describe ".group_by_resource" do
    it "groups scopes by resource type" do
      scopes = ["record:read", "record:write", "object:read", "user:read"]
      result = described_class.group_by_resource(scopes)

      expect(result).to eq(
        "record" => ["record:read", "record:write"],
        "object" => ["object:read"],
        "user" => ["user:read"]
      )
    end

    it "handles empty array" do
      expect(described_class.group_by_resource([])).to eq({})
    end

    it "handles single scope" do
      result = described_class.group_by_resource("record:read")
      expect(result).to eq("record" => ["record:read"])
    end
  end

  describe ".sufficient_for?" do
    it "returns true when exact scope is present" do
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

    it "returns false for unrelated scopes" do
      expect(
        described_class.sufficient_for?(["object:write"], resource: "record", operation: "read")
      ).to be false
    end
  end

  describe "InvalidScopeError" do
    it "is a StandardError" do
      expect(Attio::OAuth::ScopeValidator::InvalidScopeError.superclass).to eq(StandardError)
    end
  end
end
