# frozen_string_literal: true

require "spec_helper"

RSpec.describe Attio::Util::IdExtractor do
  describe ".extract" do
    it "returns string IDs as-is" do
      expect(described_class.extract("abc123")).to eq("abc123")
    end

    it "returns nil for nil input" do
      expect(described_class.extract(nil)).to be_nil
    end

    it "extracts from hash with symbol key" do
      expect(described_class.extract({webhook_id: "wh_123"}, :webhook_id)).to eq("wh_123")
    end

    it "extracts from hash with string key" do
      expect(described_class.extract({"webhook_id" => "wh_123"}, :webhook_id)).to eq("wh_123")
    end

    it "handles mixed key types" do
      expect(described_class.extract({"webhook_id" => "wh_123"}, "webhook_id")).to eq("wh_123")
    end

    it "returns nil when key not found" do
      expect(described_class.extract({other_id: "123"}, :webhook_id)).to be_nil
    end

    it "converts non-string/hash objects to string" do
      expect(described_class.extract(123)).to eq("123")
    end
  end

  describe ".extract_for_resource" do
    it "extracts webhook IDs" do
      id = {webhook_id: "wh_123", other_data: "ignored"}
      expect(described_class.extract_for_resource(id, :webhook)).to eq("wh_123")
    end

    it "extracts attribute IDs" do
      id = {"attribute_id" => "attr_123"}
      expect(described_class.extract_for_resource(id, :attribute)).to eq("attr_123")
    end

    it "handles string IDs for resources without specific keys" do
      expect(described_class.extract_for_resource("simple_id", :unknown_type)).to eq("simple_id")
    end

    it "extracts workspace member IDs" do
      id = {workspace_member_id: "wsm_123"}
      expect(described_class.extract_for_resource(id, :workspace_member)).to eq("wsm_123")
    end

    it "extracts record IDs" do
      id = {record_id: "rec_123", workspace_id: "ws_456"}
      expect(described_class.extract_for_resource(id, :record)).to eq("rec_123")
    end
  end

  describe ".normalize" do
    it "returns string for non-hash format resources" do
      expect(described_class.normalize("wh_123", :webhook)).to eq("wh_123")
    end

    it "returns hash format for record resources" do
      result = described_class.normalize({record_id: "rec_123"}, :record)
      expect(result).to eq({record_id: "rec_123"})
    end

    it "converts string to hash for record resources" do
      result = described_class.normalize("rec_123", :record)
      expect(result).to eq({record_id: "rec_123"})
    end

    it "returns nil for nil input" do
      expect(described_class.normalize(nil, :webhook)).to be_nil
    end

    it "returns nil when extraction fails" do
      expect(described_class.normalize({}, :webhook)).to be_nil
    end
  end

  describe "edge cases" do
    it "handles deeply nested structures" do
      id = {data: {webhook_id: "wh_123"}}
      # This should return nil as it doesn't directly contain webhook_id
      expect(described_class.extract_for_resource(id, :webhook)).to be_nil
    end

    it "handles empty hashes" do
      expect(described_class.extract({})).to be_nil
    end

    it "prioritizes specific key when extracting without key" do
      # When no key is specified, it should try common keys
      id = {id: "generic", webhook_id: "specific"}
      result = described_class.extract(id)
      expect(result).to eq("generic") # 'id' comes first in common_keys
    end
  end
end
