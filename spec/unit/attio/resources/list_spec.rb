# frozen_string_literal: true

require "webmock/rspec"

RSpec.describe Attio::List do
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
