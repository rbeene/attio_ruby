# frozen_string_literal: true

require "spec_helper"

RSpec.describe Attio::WorkspaceMember do
  let(:member_attributes) do
    {
      id: {workspace_member_id: "member_123"},
      email_address: "john@example.com",
      first_name: "John",
      last_name: "Doe",
      avatar_url: "https://example.com/avatar.jpg",
      access_level: "standard",
      status: "active",
      invited_at: "2023-01-10T10:00:00Z",
      last_accessed_at: "2023-01-15T15:30:00Z"
    }
  end

  describe "#initialize" do
    it "sets attributes correctly" do
      member = described_class.new(member_attributes)

      expect(member.email_address).to eq("john@example.com")
      expect(member.first_name).to eq("John")
      expect(member.last_name).to eq("Doe")
      expect(member.avatar_url).to eq("https://example.com/avatar.jpg")
      expect(member.access_level).to eq("standard")
      expect(member.status).to eq("active")
      expect(member.invited_at).to be_a(Time)
      expect(member.last_accessed_at).to be_a(Time)
    end

    it "handles string keys" do
      string_attrs = {
        "id" => {"workspace_member_id" => "member_456"},
        "email_address" => "jane@example.com",
        "first_name" => "Jane",
        "last_name" => "Smith",
        "access_level" => "admin",
        "status" => "active"
      }

      member = described_class.new(string_attrs)
      expect(member.email_address).to eq("jane@example.com")
      expect(member.first_name).to eq("Jane")
      expect(member.access_level).to eq("admin")
    end

    it "parses timestamps correctly" do
      member = described_class.new(member_attributes)
      expect(member.invited_at.iso8601).to eq("2023-01-10T10:00:00Z")
      expect(member.last_accessed_at.iso8601).to eq("2023-01-15T15:30:00Z")
    end

    it "handles nil timestamps" do
      member = described_class.new({})
      expect(member.invited_at).to be_nil
      expect(member.last_accessed_at).to be_nil
    end
  end

  describe ".resource_path" do
    it "returns the correct path" do
      expect(described_class.resource_path).to eq("workspace_members")
    end
  end

  describe "#full_name" do
    it "returns full name when both first and last name are present" do
      member = described_class.new(member_attributes)
      expect(member.full_name).to eq("John Doe")
    end

    it "returns only first name when last name is nil" do
      member = described_class.new(first_name: "John")
      expect(member.full_name).to eq("John")
    end

    it "returns only last name when first name is nil" do
      member = described_class.new(last_name: "Doe")
      expect(member.full_name).to eq("Doe")
    end

    it "returns empty string when both names are nil" do
      member = described_class.new({})
      expect(member.full_name).to eq("")
    end
  end

  describe "status methods" do
    describe "#active?" do
      it "returns true when status is active" do
        member = described_class.new(status: "active")
        expect(member.active?).to be true
      end

      it "returns false when status is not active" do
        member = described_class.new(status: "invited")
        expect(member.active?).to be false
      end
    end

    describe "#invited?" do
      it "returns true when status is invited" do
        member = described_class.new(status: "invited")
        expect(member.invited?).to be true
      end

      it "returns false when status is not invited" do
        member = described_class.new(status: "active")
        expect(member.invited?).to be false
      end
    end

    describe "#deactivated?" do
      it "returns true when status is deactivated" do
        member = described_class.new(status: "deactivated")
        expect(member.deactivated?).to be true
      end

      it "returns false when status is not deactivated" do
        member = described_class.new(status: "active")
        expect(member.deactivated?).to be false
      end
    end
  end

  describe "access level methods" do
    describe "#admin?" do
      it "returns true when access_level is admin" do
        member = described_class.new(access_level: "admin")
        expect(member.admin?).to be true
      end

      it "returns false when access_level is not admin" do
        member = described_class.new(access_level: "standard")
        expect(member.admin?).to be false
      end
    end

    describe "#standard?" do
      it "returns true when access_level is standard" do
        member = described_class.new(access_level: "standard")
        expect(member.standard?).to be true
      end

      it "returns false when access_level is not standard" do
        member = described_class.new(access_level: "admin")
        expect(member.standard?).to be false
      end
    end
  end

  describe "immutability" do
    let(:member) { described_class.new(member_attributes) }

    describe "#save" do
      it "raises NotImplementedError" do
        expect { member.save }.to raise_error(
          NotImplementedError,
          "Workspace members cannot be updated via API"
        )
      end
    end

    describe "#update" do
      it "raises NotImplementedError" do
        expect { member.update(first_name: "Jane") }.to raise_error(
          NotImplementedError,
          "Workspace members cannot be updated via API"
        )
      end
    end

    describe "#destroy" do
      it "raises NotImplementedError" do
        expect { member.destroy }.to raise_error(
          NotImplementedError,
          "Workspace members cannot be deleted via API"
        )
      end
    end
  end

  describe "#to_h" do
    it "includes all member fields" do
      member = described_class.new(member_attributes)
      hash = member.to_h

      expect(hash).to include(
        email_address: "john@example.com",
        first_name: "John",
        last_name: "Doe",
        avatar_url: "https://example.com/avatar.jpg",
        access_level: "standard",
        status: "active",
        invited_at: "2023-01-10T10:00:00Z",
        last_accessed_at: "2023-01-15T15:30:00Z"
      )
    end

    it "compacts nil values" do
      member = described_class.new(email_address: "test@example.com")
      hash = member.to_h

      expect(hash).to have_key(:email_address)
      expect(hash).not_to have_key(:first_name)
      expect(hash).not_to have_key(:last_name)
      expect(hash).not_to have_key(:invited_at)
    end

    it "formats timestamps as ISO8601" do
      timestamp = Time.parse("2023-05-01T12:00:00Z")
      member = described_class.new(invited_at: timestamp)

      expect(member.to_h[:invited_at]).to eq("2023-05-01T12:00:00Z")
    end
  end

  describe ".me" do
    it "fetches the current user" do
      self_response = {
        authorized_by_workspace_member_id: "member_me",
        workspace_id: "ws_123"
      }

      members_list = [
        described_class.new(id: {workspace_member_id: "member_other"}),
        described_class.new(id: {workspace_member_id: "member_me"}, email_address: "me@example.com"),
        described_class.new(id: {workspace_member_id: "member_another"})
      ]

      allow(described_class).to receive(:execute_request).with(
        :GET,
        "self",
        {},
        {}
      ).and_return(self_response)

      allow(described_class).to receive(:list).and_return(members_list)

      result = described_class.me
      expect(result.email_address).to eq("me@example.com")
    end

    it "passes options" do
      allow(described_class).to receive(:execute_request).with(
        :GET,
        "self",
        {},
        {api_key: "custom_key"}
      ).and_return({authorized_by_workspace_member_id: "member_me", workspace_id: "ws_123"})

      allow(described_class).to receive(:list).with(api_key: "custom_key").and_return([])

      described_class.me(api_key: "custom_key")
    end
  end

  describe ".current" do
    it "is an alias for .me" do
      expect(described_class.method(:current)).to eq(described_class.method(:me))
    end
  end

  describe ".find_by with email" do
    it "finds member by email address using Rails-style syntax" do
      members = [
        described_class.new(email_address: "alice@example.com"),
        described_class.new(email_address: "bob@example.com"),
        described_class.new(email_address: "charlie@example.com")
      ]

      allow(described_class).to receive(:list).and_return(members)

      result = described_class.find_by(email: "bob@example.com")
      expect(result.email_address).to eq("bob@example.com")
    end

    it "raises NotFoundError when member not found" do
      allow(described_class).to receive(:list).and_return([])

      expect {
        described_class.find_by(email: "nonexistent@example.com")
      }.to raise_error(
        Attio::NotFoundError,
        "Workspace member with email 'nonexistent@example.com' not found"
      )
    end

    it "passes options" do
      allow(described_class).to receive(:list).with(api_key: "custom_key").and_return([])

      expect {
        described_class.find_by(email: "test@example.com", api_key: "custom_key")
      }.to raise_error(Attio::NotFoundError)
    end
  end

  describe ".active" do
    it "returns only active members" do
      members = [
        described_class.new(status: "active", email_address: "active1@example.com"),
        described_class.new(status: "invited", email_address: "invited@example.com"),
        described_class.new(status: "active", email_address: "active2@example.com"),
        described_class.new(status: "deactivated", email_address: "deactivated@example.com")
      ]

      allow(described_class).to receive(:list).and_return(members)

      result = described_class.active
      expect(result.map(&:email_address)).to eq(["active1@example.com", "active2@example.com"])
    end

    it "passes options" do
      allow(described_class).to receive(:list).with(api_key: "custom_key").and_return([])
      described_class.active(api_key: "custom_key")
    end
  end

  describe ".admins" do
    it "returns only admin members" do
      members = [
        described_class.new(access_level: "standard", email_address: "user1@example.com"),
        described_class.new(access_level: "admin", email_address: "admin1@example.com"),
        described_class.new(access_level: "standard", email_address: "user2@example.com"),
        described_class.new(access_level: "admin", email_address: "admin2@example.com")
      ]

      allow(described_class).to receive(:list).and_return(members)

      result = described_class.admins
      expect(result.map(&:email_address)).to eq(["admin1@example.com", "admin2@example.com"])
    end

    it "passes options" do
      allow(described_class).to receive(:list).with(api_key: "custom_key").and_return([])
      described_class.admins(api_key: "custom_key")
    end
  end

  describe "unsupported operations" do
    describe ".create" do
      it "raises NotImplementedError" do
        expect {
          described_class.create(email_address: "new@example.com")
        }.to raise_error(
          NotImplementedError,
          "Workspace members cannot be created via API"
        )
      end
    end

    describe ".update" do
      it "raises NotImplementedError" do
        expect {
          described_class.update("member_123", first_name: "Updated")
        }.to raise_error(
          NotImplementedError,
          "Workspace members cannot be updated via API"
        )
      end
    end

    describe ".delete" do
      it "raises NotImplementedError" do
        expect {
          described_class.delete("member_123")
        }.to raise_error(
          NotImplementedError,
          "Workspace members cannot be deleted via API"
        )
      end
    end
  end

  describe "API operations" do
    it "provides list operation" do
      expect(described_class).to respond_to(:list)
    end

    it "provides retrieve operation" do
      expect(described_class).to respond_to(:retrieve)
    end

    it "overrides create to raise error" do
      expect { described_class.create({}) }.to raise_error(NotImplementedError)
    end

    it "overrides update to raise error" do
      expect { described_class.update("id", {}) }.to raise_error(NotImplementedError)
    end

    it "overrides delete to raise error" do
      expect { described_class.delete("id") }.to raise_error(NotImplementedError)
    end
  end

  describe "edge cases" do
    it "handles member with minimal attributes" do
      minimal = described_class.new(email_address: "minimal@example.com")
      expect(minimal.email_address).to eq("minimal@example.com")
      expect(minimal.full_name).to eq("")
      expect(minimal.active?).to be false
      expect(minimal.admin?).to be false
    end

    it "handles member with all nil values" do
      empty = described_class.new({})
      expect(empty.email_address).to be_nil
      expect(empty.full_name).to eq("")
      expect { empty.to_h }.not_to raise_error
    end
  end
end
