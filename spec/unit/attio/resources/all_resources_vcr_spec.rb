# frozen_string_literal: true

require "webmock/rspec"

RSpec.describe Attio do
  before(:all) do
    VCR.turn_off!
    WebMock.disable_net_connect!
  end

  after(:all) do
    WebMock.allow_net_connect!
    VCR.turn_on!
  end

  describe Attio::Object do
    let(:objects_list_response) do
      {
        "data" => [
          {
            "id" => {
              "workspace_id" => "a96c9c20-442b-43cd-a94b-3d4683051661",
              "object_id" => "2b522f6f-7174-4a69-83c2-cbd745f042cf"
            },
            "api_slug" => "users",
            "singular_noun" => "User",
            "plural_noun" => "Users",
            "created_at" => "2025-07-18T13:49:44.655000000Z"
          },
          {
            "id" => {
              "workspace_id" => "a96c9c20-442b-43cd-a94b-3d4683051661",
              "object_id" => "445e7c02-0068-4b3c-8937-aebbf7530920"
            },
            "api_slug" => "people",
            "singular_noun" => "Person",
            "plural_noun" => "People",
            "created_at" => "2025-07-18T13:49:44.655000000Z"
          }
        ]
      }
    end

    let(:people_object_response) do
      {
        "data" => {
          "id" => {
            "workspace_id" => "a96c9c20-442b-43cd-a94b-3d4683051661",
            "object_id" => "445e7c02-0068-4b3c-8937-aebbf7530920"
          },
          "api_slug" => "people",
          "singular_noun" => "Person",
          "plural_noun" => "People",
          "created_at" => "2025-07-18T13:49:44.655000000Z"
        }
      }
    end

    it "lists objects" do
      stub_request(:get, "https://api.attio.com/v2/objects")
        .to_return(
          status: 200,
          body: objects_list_response.to_json,
          headers: {"Content-Type" => "application/json"}
        )

      result = described_class.list
      expect(result).to be_a(Attio::APIResource::ListObject)
      expect(result.first).to be_a(described_class) if result.any?
    end

    it "retrieves a specific object" do
      stub_request(:get, "https://api.attio.com/v2/objects/people")
        .to_return(
          status: 200,
          body: people_object_response.to_json,
          headers: {"Content-Type" => "application/json"}
        )

      result = described_class.retrieve("people")
      expect(result).to be_a(described_class)
    end
  end

  describe Attio::WorkspaceMember do
    let(:workspace_members_response) do
      {
        "data" => [
          {
            "id" => {
              "workspace_id" => "a96c9c20-442b-43cd-a94b-3d4683051661",
              "workspace_member_id" => "1757c0bb-f8e6-4013-b41d-2e49a3ef2c6f"
            },
            "first_name" => "Robert",
            "last_name" => "Beene",
            "avatar_url" => "https://lh3.googleusercontent.com/a/ACg8ocL-ksS1-L-QHG4sFM9-DYrDYNym7CgBxqhiUDQYlEMQ5riPJA=s96-c",
            "email_address" => "robert@ismly.com",
            "access_level" => "admin",
            "created_at" => "2025-07-18T13:49:47.914000000Z"
          }
        ]
      }
    end

    it "lists workspace members" do
      stub_request(:get, "https://api.attio.com/v2/workspace_members")
        .to_return(
          status: 200,
          body: workspace_members_response.to_json,
          headers: {"Content-Type" => "application/json"}
        )

      result = described_class.list
      expect(result).to be_a(Attio::APIResource::ListObject)
      expect(result.first).to be_a(described_class) if result.any?
    end
  end

  describe Attio::List do
    let(:lists_response) do
      {
        "data" => [
          {
            "id" => {
              "workspace_id" => "a96c9c20-442b-43cd-a94b-3d4683051661",
              "list_id" => "b557d074-c549-4807-bc01-c4fd74cb419c"
            },
            "api_slug" => "customer_success",
            "created_at" => "2025-07-18T13:50:25.142000000Z",
            "name" => "Customer Success",
            "workspace_access" => nil,
            "workspace_member_access" => [
              {
                "level" => "full-access",
                "workspace_member_id" => "1757c0bb-f8e6-4013-b41d-2e49a3ef2c6f"
              }
            ],
            "parent_object" => ["companies"],
            "created_by_actor" => {
              "type" => "workspace-member",
              "id" => "1757c0bb-f8e6-4013-b41d-2e49a3ef2c6f"
            }
          }
        ]
      }
    end

    it "lists lists" do
      stub_request(:get, "https://api.attio.com/v2/lists")
        .to_return(
          status: 200,
          body: lists_response.to_json,
          headers: {"Content-Type" => "application/json"}
        )

      result = described_class.list
      expect(result).to be_a(Attio::APIResource::ListObject)
      expect(result.first).to be_a(described_class) if result.any?
    end

    it "creates a new list" do
      create_response = {
        "data" => {
          "id" => {
            "workspace_id" => "a96c9c20-442b-43cd-a94b-3d4683051661",
            "list_id" => "fa542089-565f-407e-847d-96a8a0592d67"
          },
          "api_slug" => "test_list",
          "created_at" => "2025-07-27T11:24:57.302000000Z",
          "name" => "Test List",
          "workspace_access" => "full-access",
          "workspace_member_access" => [],
          "parent_object" => ["people"],
          "created_by_actor" => {
            "type" => "api-token",
            "id" => "4c9b8eb9-4b5d-4b27-a37c-6a9ff08bd3ee"
          }
        }
      }

      stub_request(:post, "https://api.attio.com/v2/lists")
        .with(
          body: hash_including(
            "data" => hash_including(
              "name" => "Test List",
              "parent_object" => "people"
            )
          )
        )
        .to_return(
          status: 200,
          body: create_response.to_json,
          headers: {"Content-Type" => "application/json"}
        )

      result = described_class.create({
        object: "people",
        name: "Test List"
      })
      expect(result).to be_a(described_class)
      expect(result.persisted?).to be true
    end
  end

  describe Attio::Webhook do
    it "lists webhooks" do
      stub_request(:get, "https://api.attio.com/v2/webhooks")
        .to_return(
          status: 200,
          body: {"data" => []}.to_json,
          headers: {"Content-Type" => "application/json"}
        )

      result = described_class.list
      expect(result).to be_a(Attio::APIResource::ListObject)
    end

    it "attempts to create a new webhook (may fail with invalid URL)" do
      error_response = {
        "status_code" => 400,
        "type" => "invalid_request_error",
        "code" => "validation_type",
        "message" => "Body payload validation error.",
        "validation_errors" => [
          {
            "code" => "invalid",
            "path" => ["data", "subscriptions", 0, "filter"],
            "message" => "Invalid input"
          }
        ]
      }

      stub_request(:post, "https://api.attio.com/v2/webhooks")
        .with(
          body: {
            "data" => {
              "target_url" => "https://example.com/webhook/vcr",
              "subscriptions" => [{"event_type" => "record.created"}]
            }
          }.to_json
        )
        .to_return(
          status: 400,
          body: error_response.to_json,
          headers: {"Content-Type" => "application/json"}
        )

      # This test records the actual API response, which may be a 400 error
      # since example.com is not a valid webhook endpoint
      expect do
        described_class.create({
          target_url: "https://example.com/webhook/vcr",
          subscriptions: [{event_type: "record.created"}]
        })
      end.to raise_error(Attio::BadRequestError)
    end
  end

  describe Attio::Attribute do
    let(:attributes_list_response) do
      {
        "data" => [
          {
            "id" => {
              "workspace_id" => "a96c9c20-442b-43cd-a94b-3d4683051661",
              "object_id" => "445e7c02-0068-4b3c-8937-aebbf7530920",
              "attribute_id" => "19438e2e-a3cb-48ec-a1e7-8a3a29b1c950"
            },
            "title" => "Record ID",
            "description" => nil,
            "api_slug" => "record_id",
            "type" => "text",
            "is_system_attribute" => true,
            "is_writable" => false,
            "is_required" => false,
            "is_unique" => true,
            "is_multiselect" => false,
            "is_default_value_enabled" => false,
            "is_archived" => false,
            "default_value" => nil,
            "relationship" => nil,
            "created_at" => "2025-07-18T13:49:44.710000000Z"
          }
        ]
      }
    end

    it "lists attributes for an object" do
      stub_request(:get, "https://api.attio.com/v2/objects/people/attributes")
        .to_return(
          status: 200,
          body: attributes_list_response.to_json,
          headers: {"Content-Type" => "application/json"}
        )

      result = described_class.list({object: "people"})
      expect(result).to be_a(Attio::APIResource::ListObject)
      expect(result.first).to be_a(described_class) if result.any?
    end

    it "creates a new attribute" do
      create_response = {
        "data" => {
          "id" => {
            "workspace_id" => "a96c9c20-442b-43cd-a94b-3d4683051661",
            "object_id" => "445e7c02-0068-4b3c-8937-aebbf7530920",
            "attribute_id" => "10ea9ef1-6857-4af1-834e-a5c8864afc12"
          },
          "title" => "VCR Test Field",
          "description" => "A test field created by VCR",
          "api_slug" => "vcr_test_field",
          "type" => "text",
          "is_system_attribute" => false,
          "is_writable" => true,
          "is_required" => false,
          "is_unique" => false,
          "is_multiselect" => false,
          "is_default_value_enabled" => false,
          "is_archived" => false,
          "default_value" => nil,
          "relationship" => nil,
          "created_at" => "2025-07-27T14:06:20.785000000Z"
        }
      }

      stub_request(:post, "https://api.attio.com/v2/objects/people/attributes")
        .with(
          body: hash_including(
            "data" => hash_including(
              "title" => "VCR Test Field",
              "type" => "text",
              "description" => "A test field created by VCR"
            )
          )
        )
        .to_return(
          status: 200,
          body: create_response.to_json,
          headers: {"Content-Type" => "application/json"}
        )

      result = described_class.create({
        object: "people",
        name: "VCR Test Field",
        type: "text",
        description: "A test field created by VCR"
      })
      expect(result).to be_a(described_class)
      expect(result.persisted?).to be true
    end
  end

  describe Attio::Note do
    let(:record_id) { "0174bfac-74b9-41de-b757-c6fa2a68ab00" }

    it "creates a new note" do
      create_response = {
        "data" => {
          "id" => {
            "workspace_id" => "a96c9c20-442b-43cd-a94b-3d4683051661",
            "note_id" => "2c06b1a4-e6a4-4c14-a26c-b9af56bcdd64"
          },
          "parent_object" => "people",
          "parent_record_id" => "0174bfac-74b9-41de-b757-c6fa2a68ab00",
          "title" => "VCR Test Note",
          "content_plaintext" => "This is a test note created by VCR",
          "content_markdown" => "This is a test note created by VCR",
          "tags" => [],
          "created_by_actor" => {
            "type" => "api-token",
            "id" => "4c9b8eb9-4b5d-4b27-a37c-6a9ff08bd3ee"
          },
          "created_at" => "2025-07-27T01:46:57.651000000Z"
        }
      }

      stub_request(:post, "https://api.attio.com/v2/notes")
        .with(
          body: {
            "data" => {
              "title" => "VCR Test Note",
              "parent_object" => "people",
              "parent_record_id" => record_id,
              "content" => "This is a test note created by VCR",
              "format" => "plaintext"
            }
          }.to_json
        )
        .to_return(
          status: 200,
          body: create_response.to_json,
          headers: {"Content-Type" => "application/json"}
        )

      result = described_class.create({
        object: "people",
        record_id: record_id,
        title: "VCR Test Note",
        content: "This is a test note created by VCR",
        format: "plaintext"
      })
      expect(result).to be_a(described_class)
      expect(result.persisted?).to be true
    end
  end
end
