# frozen_string_literal: true

require "spec_helper"
require "webmock/rspec"

RSpec.describe Attio::WorkspaceMember do
  before do
    # Disable VCR for these unit tests to use WebMock instead
    VCR.turn_off!
    WebMock.enable!
  end

  after do
    VCR.turn_on!
  end

  let(:member_data) do
    {
      "id" => {
        "workspace_id" => "a96c9c20-442b-43cd-a94b-3d4683051661",
        "workspace_member_id" => "1757c0bb-f8e6-4013-b41d-2e49a3ef2c6f"
      },
      "first_name" => "Robert",
      "last_name" => "Beene",
      "avatar_url" => "https://lh3.googleusercontent.com/a/example",
      "email_address" => "robert@ismly.com",
      "access_level" => "admin",
      "status" => "active",
      "invited_at" => "2025-07-18T13:49:47.914000000Z",
      "last_accessed_at" => "2025-07-27T15:00:00.000000000Z",
      "created_at" => "2025-07-18T13:49:47.914000000Z"
    }
  end

  describe ".list" do
    it "lists workspace members" do
      stub_request(:get, "https://api.attio.com/v2/workspace_members")
        .to_return(
          status: 200,
          body: {"data" => [member_data]}.to_json,
          headers: {"Content-Type" => "application/json"}
        )

      result = described_class.list
      expect(result).to be_a(Attio::APIResource::ListObject)
      expect(result.first).to be_a(described_class)
      expect(result.first.email_address).to eq("robert@ismly.com")
    end
  end

  describe ".retrieve" do
    it "retrieves a specific workspace member" do
      member_id = "1757c0bb-f8e6-4013-b41d-2e49a3ef2c6f"

      stub_request(:get, "https://api.attio.com/v2/workspace_members/#{member_id}")
        .to_return(
          status: 200,
          body: {"data" => member_data}.to_json,
          headers: {"Content-Type" => "application/json"}
        )

      member = described_class.retrieve(member_id)
      expect(member).to be_a(described_class)
      expect(member.id["workspace_member_id"]).to eq(member_id)
    end
  end

  describe ".me" do
    it "retrieves the current user" do
      self_response = {
        "authorized_by_workspace_member_id" => "1757c0bb-f8e6-4013-b41d-2e49a3ef2c6f",
        "workspace_id" => "a96c9c20-442b-43cd-a94b-3d4683051661"
      }

      stub_request(:get, "https://api.attio.com/v2/self")
        .to_return(
          status: 200,
          body: self_response.to_json,
          headers: {"Content-Type" => "application/json"}
        )

      stub_request(:get, "https://api.attio.com/v2/workspace_members")
        .to_return(
          status: 200,
          body: {"data" => [member_data]}.to_json,
          headers: {"Content-Type" => "application/json"}
        )

      member = described_class.me
      expect(member).to be_a(described_class)
      expect(member.id["workspace_member_id"]).to eq("1757c0bb-f8e6-4013-b41d-2e49a3ef2c6f")
    end
  end

  describe ".current" do
    it "is an alias for .me" do
      expect(described_class.method(:current)).to eq(described_class.method(:me))
    end
  end

  describe ".find_by_email" do
    it "finds a member by email" do
      stub_request(:get, "https://api.attio.com/v2/workspace_members")
        .to_return(
          status: 200,
          body: {"data" => [member_data]}.to_json,
          headers: {"Content-Type" => "application/json"}
        )

      member = described_class.find_by_email("robert@ismly.com")
      expect(member).to be_a(described_class)
      expect(member.email_address).to eq("robert@ismly.com")
    end

    it "raises NotFoundError when member not found" do
      stub_request(:get, "https://api.attio.com/v2/workspace_members")
        .to_return(
          status: 200,
          body: {"data" => []}.to_json,
          headers: {"Content-Type" => "application/json"}
        )

      expect {
        described_class.find_by_email("nonexistent@example.com")
      }.to raise_error(Attio::NotFoundError, "Workspace member with email 'nonexistent@example.com' not found")
    end
  end

  describe ".active" do
    it "returns only active members" do
      inactive_member = member_data.merge("status" => "deactivated")

      stub_request(:get, "https://api.attio.com/v2/workspace_members")
        .to_return(
          status: 200,
          body: {"data" => [member_data, inactive_member]}.to_json,
          headers: {"Content-Type" => "application/json"}
        )

      active_members = described_class.active
      expect(active_members).to all(be_a(described_class))
      expect(active_members.map(&:status)).to all(eq("active"))
    end
  end

  describe ".admins" do
    it "returns only admin members" do
      standard_member = member_data.merge("access_level" => "standard")

      stub_request(:get, "https://api.attio.com/v2/workspace_members")
        .to_return(
          status: 200,
          body: {"data" => [member_data, standard_member]}.to_json,
          headers: {"Content-Type" => "application/json"}
        )

      admin_members = described_class.admins
      expect(admin_members).to all(be_a(described_class))
      expect(admin_members.map(&:access_level)).to all(eq("admin"))
    end
  end

  describe "unsupported operations" do
    it "raises NotImplementedError for .create" do
      expect {
        described_class.create({})
      }.to raise_error(NotImplementedError, "Workspace members cannot be created via API")
    end

    it "raises NotImplementedError for .update" do
      expect {
        described_class.update("123", {})
      }.to raise_error(NotImplementedError, "Workspace members cannot be updated via API")
    end

    it "raises NotImplementedError for .delete" do
      expect {
        described_class.delete("123")
      }.to raise_error(NotImplementedError, "Workspace members cannot be deleted via API")
    end
  end

  describe "instance methods" do
    let(:member) { described_class.new(member_data) }

    describe "#initialize" do
      it "sets the email address" do
        expect(member.email_address).to eq("robert@ismly.com")
      end

      it "sets the name attributes" do
        expect(member.first_name).to eq("Robert")
        expect(member.last_name).to eq("Beene")
      end

      it "sets the avatar URL" do
        expect(member.avatar_url).to eq("https://lh3.googleusercontent.com/a/example")
      end

      it "sets the access level" do
        expect(member.access_level).to eq("admin")
      end

      it "sets the status" do
        expect(member.status).to eq("active")
      end

      it "parses timestamps correctly" do
        expect(member.invited_at).to be_a(Time)
        expect(member.last_accessed_at).to be_a(Time)
      end

      it "handles missing optional fields" do
        minimal_data = {
          "id" => member_data["id"],
          "email_address" => "test@example.com",
          "access_level" => "standard"
        }

        member = described_class.new(minimal_data)
        expect(member.first_name).to be_nil
        expect(member.last_name).to be_nil
        expect(member.avatar_url).to be_nil
        expect(member.invited_at).to be_nil
        expect(member.last_accessed_at).to be_nil
      end
    end

    describe "#full_name" do
      it "returns full name when both names present" do
        expect(member.full_name).to eq("Robert Beene")
      end

      it "returns only first name when last name missing" do
        member_data["last_name"] = nil
        member = described_class.new(member_data)
        expect(member.full_name).to eq("Robert")
      end

      it "returns only last name when first name missing" do
        member_data["first_name"] = nil
        member = described_class.new(member_data)
        expect(member.full_name).to eq("Beene")
      end

      it "returns empty string when both names missing" do
        member_data["first_name"] = nil
        member_data["last_name"] = nil
        member = described_class.new(member_data)
        expect(member.full_name).to eq("")
      end
    end

    describe "status methods" do
      describe "#active?" do
        it "returns true when status is active" do
          expect(member.active?).to be true
        end

        it "returns false when status is not active" do
          member_data["status"] = "invited"
          member = described_class.new(member_data)
          expect(member.active?).to be false
        end
      end

      describe "#invited?" do
        it "returns true when status is invited" do
          member_data["status"] = "invited"
          member = described_class.new(member_data)
          expect(member.invited?).to be true
        end

        it "returns false when status is not invited" do
          expect(member.invited?).to be false
        end
      end

      describe "#deactivated?" do
        it "returns true when status is deactivated" do
          member_data["status"] = "deactivated"
          member = described_class.new(member_data)
          expect(member.deactivated?).to be true
        end

        it "returns false when status is not deactivated" do
          expect(member.deactivated?).to be false
        end
      end
    end

    describe "access level methods" do
      describe "#admin?" do
        it "returns true when access_level is admin" do
          expect(member.admin?).to be true
        end

        it "returns false when access_level is not admin" do
          member_data["access_level"] = "standard"
          member = described_class.new(member_data)
          expect(member.admin?).to be false
        end
      end

      describe "#standard?" do
        it "returns true when access_level is standard" do
          member_data["access_level"] = "standard"
          member = described_class.new(member_data)
          expect(member.standard?).to be true
        end

        it "returns false when access_level is not standard" do
          expect(member.standard?).to be false
        end
      end
    end

    describe "unsupported instance operations" do
      it "raises NotImplementedError for #save" do
        expect {
          member.save
        }.to raise_error(NotImplementedError, "Workspace members cannot be updated via API")
      end

      it "raises NotImplementedError for #update" do
        expect {
          member.update({})
        }.to raise_error(NotImplementedError, "Workspace members cannot be updated via API")
      end

      it "raises NotImplementedError for #destroy" do
        expect {
          member.destroy
        }.to raise_error(NotImplementedError, "Workspace members cannot be deleted via API")
      end
    end

    describe "#to_h" do
      it "returns a hash representation" do
        hash = member.to_h
        expect(hash).to include(
          :id,
          :email_address,
          :first_name,
          :last_name,
          :avatar_url,
          :access_level,
          :status
        )
        expect(hash[:invited_at]).to match(/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z/)
        expect(hash[:last_accessed_at]).to match(/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z/)
      end

      it "excludes nil values" do
        minimal_data = {
          "id" => member_data["id"],
          "email_address" => "test@example.com",
          "access_level" => "standard"
        }

        member = described_class.new(minimal_data)
        hash = member.to_h
        expect(hash).not_to have_key(:first_name)
        expect(hash).not_to have_key(:last_name)
        expect(hash).not_to have_key(:avatar_url)
        expect(hash).not_to have_key(:invited_at)
        expect(hash).not_to have_key(:last_accessed_at)
      end
    end
  end
end
