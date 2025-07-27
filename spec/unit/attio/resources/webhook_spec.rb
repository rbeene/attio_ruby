# frozen_string_literal: true

require "webmock/rspec"

RSpec.describe Attio::Webhook do
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