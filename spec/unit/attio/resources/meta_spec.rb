# frozen_string_literal: true

require "spec_helper"

RSpec.describe Attio::Meta do
  # This is the ACTUAL structure returned by the API - flat JWT-like format
  let(:meta_attributes) do
    {
      active: true,
      scope: "record:read record:write list:read-write",
      client_id: "token_123",
      token_type: "Bearer",
      iat: 1754399952,
      sub: "ws_123",
      aud: "token_123",
      iss: "attio.com",
      authorized_by_workspace_member_id: "member_123",
      workspace_id: "ws_123",
      workspace_name: "Test Workspace",
      workspace_slug: "test-workspace",
      workspace_logo_url: "https://assets.attio.com/logos/test.png"
    }
  end

  describe ".resource_path" do
    it "returns the correct path" do
      expect(described_class.resource_path).to eq("self")
    end
  end

  describe ".identify" do
    it "fetches the current token and workspace info" do
      allow(described_class).to receive(:execute_request).with(
        :GET,
        "self",
        {},
        {}
      ).and_return({"data" => meta_attributes})

      result = described_class.identify
      expect(result).to be_a(described_class)
      expect(result.workspace[:name]).to eq("Test Workspace")
    end

    it "handles response without data wrapper" do
      allow(described_class).to receive(:execute_request).and_return(meta_attributes)

      result = described_class.identify
      expect(result.workspace[:name]).to eq("Test Workspace")
    end

    it "passes options" do
      allow(described_class).to receive(:execute_request).with(
        :GET,
        "self",
        {},
        {api_key: "custom_key"}
      ).and_return({"data" => meta_attributes})

      described_class.identify(api_key: "custom_key")
    end
  end

  describe ".self" do
    it "is an alias for identify" do
      expect(described_class.method(:self)).to eq(described_class.method(:identify))
    end
  end

  describe ".current" do
    it "is an alias for identify" do
      expect(described_class.method(:current)).to eq(described_class.method(:identify))
    end
  end

  describe "#initialize" do
    it "builds workspace, token, and actor from flat attributes" do
      meta = described_class.new(meta_attributes)

      expect(meta.workspace).to eq({
        id: "ws_123",
        name: "Test Workspace",
        slug: "test-workspace",
        logo_url: "https://assets.attio.com/logos/test.png"
      })

      expect(meta.token).to eq({
        id: "token_123",
        type: "Bearer",
        scope: "record:read record:write list:read-write"
      })

      expect(meta.actor).to eq({
        type: "workspace-member",
        id: "member_123"
      })
    end
  end

  describe "workspace methods" do
    let(:meta) { described_class.new(meta_attributes) }

    describe "#workspace_id" do
      it "returns the workspace ID" do
        expect(meta.workspace_id).to eq("ws_123")
      end

      it "returns nil when workspace is nil" do
        meta_without_workspace = described_class.new({})
        expect(meta_without_workspace.workspace_id).to be_nil
      end
    end

    describe "#workspace_name" do
      it "returns the workspace name" do
        expect(meta.workspace_name).to eq("Test Workspace")
      end

      it "returns nil when workspace is nil" do
        meta_without_workspace = described_class.new({})
        expect(meta_without_workspace.workspace_name).to be_nil
      end
    end

    describe "#workspace_slug" do
      it "returns the workspace slug" do
        expect(meta.workspace_slug).to eq("test-workspace")
      end

      it "returns nil when workspace is nil" do
        meta_without_workspace = described_class.new({})
        expect(meta_without_workspace.workspace_slug).to be_nil
      end
    end
  end

  describe "token methods" do
    let(:meta) { described_class.new(meta_attributes) }

    describe "#token_id" do
      it "returns the token ID" do
        expect(meta.token_id).to eq("token_123")
      end

      it "returns nil when token is nil" do
        meta_without_token = described_class.new({})
        expect(meta_without_token.token_id).to be_nil
      end
    end

    describe "#token_name" do
      it "returns nil (not available in flat format)" do
        expect(meta.token_name).to be_nil
      end

      it "returns nil when token is nil" do
        meta_without_token = described_class.new({})
        expect(meta_without_token.token_name).to be_nil
      end
    end

    describe "#token_type" do
      it "returns the token type" do
        expect(meta.token_type).to eq("Bearer")
      end

      it "returns nil when token is nil" do
        meta_without_token = described_class.new({})
        expect(meta_without_token.token_type).to be_nil
      end
    end
  end

  describe "scope methods" do
    let(:meta) { described_class.new(meta_attributes) }

    describe "#scopes" do
      it "returns the token scopes" do
        expect(meta.scopes).to eq(["record:read", "record:write", "list:read-write"])
      end

      it "returns empty array when token is nil" do
        meta_without_token = described_class.new({})
        expect(meta_without_token.scopes).to eq([])
      end

      it "returns empty array when scope is nil" do
        meta_without_scopes = described_class.new(client_id: "token_123")
        expect(meta_without_scopes.scopes).to eq([])
      end
    end

    describe "#has_scope?" do
      it "returns true for existing scope" do
        expect(meta.has_scope?("record:read")).to be true
        expect(meta.has_scope?("record:write")).to be true
      end

      it "returns false for missing scope" do
        expect(meta.has_scope?("record:delete")).to be false
      end

      it "converts underscores to colons" do
        expect(meta.has_scope?("record_read")).to be true
      end

      it "handles symbol input" do
        expect(meta.has_scope?(:record_read)).to be true
      end
    end

    describe "#can_read?" do
      it "returns true for read scope" do
        expect(meta.can_read?("record")).to be true
      end

      it "returns true for read-write scope" do
        expect(meta.can_read?("list")).to be true
      end

      it "returns false for write-only scope" do
        meta_write_only = described_class.new(
          scope: "record:write"
        )
        expect(meta_write_only.can_read?("record")).to be false
      end

      it "returns false for missing scope" do
        expect(meta.can_read?("webhook")).to be false
      end
    end

    describe "#can_write?" do
      it "returns true for write scope" do
        expect(meta.can_write?("record")).to be true
      end

      it "returns true for read-write scope" do
        expect(meta.can_write?("list")).to be true
      end

      it "returns false for read-only scope" do
        meta_read_only = described_class.new(
          scope: "record:read"
        )
        expect(meta_read_only.can_write?("record")).to be false
      end

      it "returns false for missing scope" do
        expect(meta.can_write?("webhook")).to be false
      end
    end
  end

  describe "#immutable?" do
    it "returns true" do
      meta = described_class.new(meta_attributes)
      expect(meta.immutable?).to be true
    end
  end

  describe "#save" do
    it "raises InvalidRequestError" do
      meta = described_class.new(meta_attributes)
      expect {
        meta.save
      }.to raise_error(
        Attio::InvalidRequestError,
        "Meta information is read-only"
      )
    end
  end

  describe "#destroy" do
    it "raises InvalidRequestError" do
      meta = described_class.new(meta_attributes)
      expect {
        meta.destroy
      }.to raise_error(
        Attio::InvalidRequestError,
        "Meta information is read-only"
      )
    end
  end

  describe "#to_h" do
    it "includes all meta fields built from flat attributes" do
      meta = described_class.new(meta_attributes)
      hash = meta.send(:to_h)

      expect(hash).to eq({
        workspace: {
          id: "ws_123",
          name: "Test Workspace",
          slug: "test-workspace",
          logo_url: "https://assets.attio.com/logos/test.png"
        },
        token: {
          id: "token_123",
          type: "Bearer",
          scope: "record:read record:write list:read-write"
        },
        actor: {
          type: "workspace-member",
          id: "member_123"
        }
      })
    end

    it "compacts nil values" do
      meta = described_class.new(workspace_id: "ws_123")
      hash = meta.send(:to_h)

      expect(hash).to have_key(:workspace)
      expect(hash).not_to have_key(:token)
      expect(hash).not_to have_key(:actor)
    end
  end

  describe "#inspect" do
    it "includes workspace slug and token name" do
      meta = described_class.new(meta_attributes)
      inspection = meta.send(:inspect)

      expect(inspection).to include("workspace=\"test-workspace\"")
      expect(inspection).to include("token=nil")
      expect(inspection).to include("Attio::Meta")
    end

    it "handles nil values" do
      meta = described_class.new({})
      inspection = meta.send(:inspect)

      expect(inspection).to include("workspace=nil")
      expect(inspection).to include("token=nil")
    end
  end

  describe "edge cases" do
    it "handles empty attributes" do
      meta = described_class.new({})
      expect(meta.workspace).to be_nil
      expect(meta.token).to be_nil
      expect(meta.actor).to be_nil
    end

    it "handles missing attributes gracefully" do
      meta = described_class.new({})
      expect { meta.workspace_id }.not_to raise_error
      expect { meta.token_name }.not_to raise_error
      expect { meta.has_scope?("any") }.not_to raise_error
    end
  end
end
