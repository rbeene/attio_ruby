# frozen_string_literal: true

require "spec_helper"

RSpec.describe Attio::Webhook do
  let(:webhook_data) do
    {
      "id" => {"webhook_id" => "webhook_123"},
      "target_url" => "https://example.com/webhooks",
      "subscriptions" => [{"event_type" => "record.created"}],
      "status" => "active",
      "secret" => "test_secret_123",
      "created_at" => "2024-01-01T00:00:00Z"
    }
  end

  let(:webhook) { described_class.new(webhook_data) }
  let(:payload) { {"event_type" => "record.created", "data" => {"id" => "rec_123"}} }
  let(:timestamp) { Time.now.to_i.to_s }
  let(:signature) { Attio::Util::WebhookSignature.calculate_signature(payload.to_json, timestamp, webhook.secret) }

  describe "instance methods" do
    describe "#verify_signature" do
      it "returns true for valid signature" do
        result = webhook.verify_signature(
          payload: payload.to_json,
          signature: signature,
          timestamp: timestamp
        )
        expect(result).to be true
      end

      it "returns false for invalid signature" do
        result = webhook.verify_signature(
          payload: payload.to_json,
          signature: "v1=invalid",
          timestamp: timestamp
        )
        expect(result).to be false
      end

      it "returns false for old timestamp" do
        old_timestamp = (Time.now.to_i - 400).to_s
        result = webhook.verify_signature(
          payload: payload.to_json,
          signature: signature,
          timestamp: old_timestamp
        )
        expect(result).to be false
      end

      it "raises error when secret is not available" do
        webhook_without_secret = described_class.new(webhook_data.except("secret"))
        expect do
          webhook_without_secret.verify_signature(
            payload: payload.to_json,
            signature: signature,
            timestamp: timestamp
          )
        end.to raise_error(Attio::InvalidRequestError, "Webhook secret not available")
      end
    end

    describe "#verify_signature!" do
      it "returns true for valid signature" do
        result = webhook.verify_signature!(
          payload: payload.to_json,
          signature: signature,
          timestamp: timestamp
        )
        expect(result).to be true
      end

      it "raises error for invalid signature" do
        expect do
          webhook.verify_signature!(
            payload: payload.to_json,
            signature: "v1=invalid",
            timestamp: timestamp
          )
        end.to raise_error(Attio::Util::WebhookSignature::SignatureVerificationError)
      end
    end

    describe "#create_handler" do
      it "creates a webhook handler with the webhook's secret" do
        handler = webhook.create_handler
        expect(handler).to be_a(Attio::Util::WebhookSignature::Handler)
        expect(handler.secret).to eq(webhook.secret)
      end

      it "raises error when secret is not available" do
        webhook_without_secret = described_class.new(webhook_data.except("secret"))
        expect do
          webhook_without_secret.create_handler
        end.to raise_error(Attio::InvalidRequestError, "Webhook secret not available")
      end
    end
  end

  describe "class methods" do
    let(:headers) do
      {
        "x-attio-signature" => signature,
        "x-attio-timestamp" => timestamp
      }
    end

    let(:request) do
      {
        headers: headers,
        body: payload.to_json
      }
    end

    describe ".verify_request" do
      it "returns true for valid request" do
        result = described_class.verify_request(request, secret: webhook.secret)
        expect(result).to be true
      end

      it "returns false for invalid signature" do
        request[:headers]["x-attio-signature"] = "v1=invalid"
        result = described_class.verify_request(request, secret: webhook.secret)
        expect(result).to be false
      end

      it "returns false for missing headers" do
        request[:headers].delete("x-attio-signature")
        result = described_class.verify_request(request, secret: webhook.secret)
        expect(result).to be false
      end
    end

    describe ".parse_and_verify" do
      it "returns parsed payload for valid request" do
        result = described_class.parse_and_verify(request, secret: webhook.secret)
        expect(result).to eq(event_type: "record.created", data: {id: "rec_123"})
      end

      it "raises error for invalid signature" do
        request[:headers]["x-attio-signature"] = "v1=invalid"
        expect do
          described_class.parse_and_verify(request, secret: webhook.secret)
        end.to raise_error(Attio::Util::WebhookSignature::SignatureVerificationError)
      end

      it "raises error for invalid JSON" do
        request[:body] = "invalid json"
        request[:headers]["x-attio-signature"] = Attio::Util::WebhookSignature.calculate_signature(
          "invalid json", timestamp, webhook.secret
        )
        expect do
          described_class.parse_and_verify(request, secret: webhook.secret)
        end.to raise_error(Attio::Util::WebhookSignature::SignatureVerificationError, /Invalid JSON payload/)
      end
    end

    describe ".create_handler" do
      it "creates a webhook handler with the provided secret" do
        handler = described_class.create_handler(secret: "test_secret")
        expect(handler).to be_a(Attio::Util::WebhookSignature::Handler)
        expect(handler.secret).to eq("test_secret")
      end

      it "raises error for nil secret" do
        expect do
          described_class.create_handler(secret: nil)
        end.to raise_error(ArgumentError, "Webhook secret is required")
      end
    end
  end

  describe "webhook verification workflow" do
    let(:event_payload) do
      {
        "event_type" => "record.created",
        "data" => {
          "object" => "people",
          "record" => {"id" => "rec_123", "values" => {"name" => "John Doe"}}
        }
      }
    end

    let(:valid_request) do
      timestamp = Time.now.to_i.to_s
      signature = Attio::Util::WebhookSignature.calculate_signature(
        event_payload.to_json,
        timestamp,
        webhook.secret
      )
      {
        headers: {
          "x-attio-signature" => signature,
          "x-attio-timestamp" => timestamp,
          "content-type" => "application/json"
        },
        body: event_payload.to_json
      }
    end

    it "verifies and parses webhook payloads" do
      parsed = described_class.parse_and_verify(valid_request, secret: webhook.secret)
      expect(parsed[:event_type]).to eq("record.created")
      expect(parsed[:data][:object]).to eq("people")
      expect(parsed[:data][:record][:values][:name]).to eq("John Doe")
    end
  end
end
