# frozen_string_literal: true

require "webmock/rspec"

RSpec.describe Attio::Note do
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
