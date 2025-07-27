# frozen_string_literal: true

require "spec_helper"

RSpec.describe Attio::Meta do
  let(:meta_data) do
    {
      workspace: {
        id: "test-workspace-id",
        name: "Test Workspace",
        slug: "test-workspace"
      },
      token: {
        type: "api-token",
        id: "test-token-id",
        name: "Test API Token",
        scopes: ["record:read", "record:write", "list:read"]
      },
      actor: {
        type: "api-token",
        id: "test-token-id"
      }
    }
  end

  describe ".identify" do
    let(:response) do
      {
        "data" => meta_data
      }
    end

    before do
      allow(Attio::Meta).to receive(:execute_request).and_return(response)
    end

    it "sends a GET request to /v2/self" do
      expect(Attio::Meta).to receive(:execute_request).with(
        :GET,
        "self",
        {},
        {}
      )

      Attio::Meta.identify
    end

    it "returns a Meta instance" do
      result = Attio::Meta.identify
      expect(result).to be_a(Attio::Meta)
    end

    it "accepts optional parameters" do
      expect(Attio::Meta).to receive(:execute_request).with(
        :GET,
        "self",
        {},
        { api_key: "custom-key" }
      )

      Attio::Meta.identify(api_key: "custom-key")
    end
  end

  describe ".self" do
    it "is an alias for identify" do
      expect(Attio::Meta.method(:self)).to eq(Attio::Meta.method(:identify))
    end
  end

  describe ".current" do
    it "is an alias for identify" do
      expect(Attio::Meta.method(:current)).to eq(Attio::Meta.method(:identify))
    end
  end

  describe "instance methods" do
    let(:meta) { Attio::Meta.new(meta_data) }

    describe "#workspace" do
      it "returns the workspace information" do
        expect(meta.workspace).to be_a(Hash)
        expect(meta.workspace[:id]).to eq("test-workspace-id")
        expect(meta.workspace[:name]).to eq("Test Workspace")
        expect(meta.workspace[:slug]).to eq("test-workspace")
      end
    end

    describe "#token" do
      it "returns the token information" do
        expect(meta.token).to be_a(Hash)
        expect(meta.token[:type]).to eq("api-token")
        expect(meta.token[:id]).to eq("test-token-id")
        expect(meta.token[:name]).to eq("Test API Token")
      end
    end

    describe "#scopes" do
      it "returns the token scopes" do
        expect(meta.scopes).to be_an(Array)
        expect(meta.scopes).to include("record:read", "record:write", "list:read")
      end
    end

    describe "#actor" do
      it "returns the actor information" do
        expect(meta.actor).to be_a(Hash)
        expect(meta.actor[:type]).to eq("api-token")
        expect(meta.actor[:id]).to eq("test-token-id")
      end
    end

    describe "#workspace_id" do
      it "returns the workspace ID" do
        expect(meta.workspace_id).to eq("test-workspace-id")
      end
    end

    describe "#workspace_name" do
      it "returns the workspace name" do
        expect(meta.workspace_name).to eq("Test Workspace")
      end
    end

    describe "#workspace_slug" do
      it "returns the workspace slug" do
        expect(meta.workspace_slug).to eq("test-workspace")
      end
    end

    describe "#token_id" do
      it "returns the token ID" do
        expect(meta.token_id).to eq("test-token-id")
      end
    end

    describe "#token_name" do
      it "returns the token name" do
        expect(meta.token_name).to eq("Test API Token")
      end
    end

    describe "#token_type" do
      it "returns the token type" do
        expect(meta.token_type).to eq("api-token")
      end
    end

    describe "#has_scope?" do
      it "returns true for existing scopes" do
        expect(meta.has_scope?("record:read")).to eq(true)
        expect(meta.has_scope?("record:write")).to eq(true)
      end

      it "returns false for non-existing scopes" do
        expect(meta.has_scope?("admin:write")).to eq(false)
      end

      it "handles symbol input" do
        expect(meta.has_scope?(:record_read)).to eq(true)
      end
    end

    describe "#can_read?" do
      it "returns true when has read scopes" do
        expect(meta.can_read?("record")).to eq(true)
      end

      it "returns false when missing read scopes" do
        expect(meta.can_read?("admin")).to eq(false)
      end
    end

    describe "#can_write?" do
      it "returns true when has write scopes" do
        expect(meta.can_write?("record")).to eq(true)
      end

      it "returns false when missing write scopes" do
        expect(meta.can_write?("list")).to eq(false)
      end
    end

    describe "#immutable?" do
      it "returns true since meta is read-only" do
        expect(meta.immutable?).to eq(true)
      end
    end

    describe "#save" do
      it "raises an error since meta is read-only" do
        expect { meta.save }.to raise_error(Attio::InvalidRequestError, "Meta information is read-only")
      end
    end

    describe "#destroy" do
      it "raises an error since meta is read-only" do
        expect { meta.destroy }.to raise_error(Attio::InvalidRequestError, "Meta information is read-only")
      end
    end
  end
end