# frozen_string_literal: true

require "webmock/rspec"

RSpec.describe Attio::Object do
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