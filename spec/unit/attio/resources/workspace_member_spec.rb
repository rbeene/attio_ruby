# frozen_string_literal: true

require "webmock/rspec"

RSpec.describe Attio::WorkspaceMember do
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