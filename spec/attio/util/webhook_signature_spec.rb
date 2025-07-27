# frozen_string_literal: true

require "spec_helper"
require "json"
require "time"

RSpec.describe Attio::Util::WebhookSignature do
  let(:secret) { "webhook_secret_123" }
  let(:payload) { '{"event":"record.created","data":{"id":"123"}}' }
  let(:timestamp) { Time.now.to_i.to_s }
  let(:valid_signature) do
    signed_payload = "#{timestamp}.#{payload}"
    hmac = OpenSSL::HMAC.hexdigest("SHA256", secret, signed_payload)
    "v1=#{hmac}"
  end

  describe ".verify!" do
    context "when ArgumentError is wrapped" do
      it "re-raises as SignatureVerificationError" do
        # Force an ArgumentError to be caught and re-raised
        allow(described_class).to receive(:validate_inputs!).and_raise(ArgumentError, "Test error")

        expect {
          described_class.verify!(
            payload: payload,
            signature: valid_signature,
            timestamp: timestamp,
            secret: secret
          )
        }.to raise_error(Attio::Util::WebhookSignature::SignatureVerificationError, /Test error/)
      end
    end

    context "with valid signature" do
      it "returns true when signature is valid" do
        expect(
          described_class.verify!(
            payload: payload,
            signature: valid_signature,
            timestamp: timestamp,
            secret: secret
          )
        ).to be true
      end

      it "accepts hash payload and converts to JSON" do
        hash_payload = {event: "record.created", data: {id: "123"}}
        json_payload = JSON.generate(hash_payload)
        signed_payload = "#{timestamp}.#{json_payload}"
        hmac = OpenSSL::HMAC.hexdigest("SHA256", secret, signed_payload)
        signature = "v1=#{hmac}"

        expect(
          described_class.verify!(
            payload: hash_payload,
            signature: signature,
            timestamp: timestamp,
            secret: secret
          )
        ).to be true
      end
    end

    context "with invalid signature" do
      it "raises SignatureVerificationError for wrong signature" do
        expect {
          described_class.verify!(
            payload: payload,
            signature: "v1=invalid_signature",
            timestamp: timestamp,
            secret: secret
          )
        }.to raise_error(Attio::Util::WebhookSignature::SignatureVerificationError)
      end

      it "raises SignatureVerificationError for wrong secret" do
        expect {
          described_class.verify!(
            payload: payload,
            signature: valid_signature,
            timestamp: timestamp,
            secret: "wrong_secret"
          )
        }.to raise_error(Attio::Util::WebhookSignature::SignatureVerificationError)
      end
    end

    context "with invalid timestamp" do
      it "raises error when timestamp is too old" do
        old_timestamp = (Time.now.to_i - 400).to_s # 400 seconds ago
        old_signature = described_class.calculate_signature(payload, old_timestamp, secret)

        expect {
          described_class.verify!(
            payload: payload,
            signature: old_signature,
            timestamp: old_timestamp,
            secret: secret
          )
        }.to raise_error(Attio::Util::WebhookSignature::SignatureVerificationError, /too old/)
      end

      it "raises error when timestamp is too far in future" do
        future_timestamp = (Time.now.to_i + 400).to_s # 400 seconds in future
        future_signature = described_class.calculate_signature(payload, future_timestamp, secret)

        expect {
          described_class.verify!(
            payload: payload,
            signature: future_signature,
            timestamp: future_timestamp,
            secret: secret
          )
        }.to raise_error(Attio::Util::WebhookSignature::SignatureVerificationError, /too far in the future/)
      end

      it "accepts custom tolerance" do
        old_timestamp = (Time.now.to_i - 100).to_s # 100 seconds ago
        old_signature = described_class.calculate_signature(payload, old_timestamp, secret)

        # Should fail with default tolerance
        expect {
          described_class.verify!(
            payload: payload,
            signature: old_signature,
            timestamp: old_timestamp,
            secret: secret,
            tolerance: 60 # 60 second tolerance
          )
        }.to raise_error(Attio::Util::WebhookSignature::SignatureVerificationError, /too old/)

        # Should succeed with larger tolerance
        expect(
          described_class.verify!(
            payload: payload,
            signature: old_signature,
            timestamp: old_timestamp,
            secret: secret,
            tolerance: 120 # 120 second tolerance
          )
        ).to be true
      end
    end

    context "with invalid inputs" do
      it "raises SignatureVerificationError for nil payload" do
        expect {
          described_class.verify!(
            payload: nil,
            signature: valid_signature,
            timestamp: timestamp,
            secret: secret
          )
        }.to raise_error(Attio::Util::WebhookSignature::SignatureVerificationError, /Payload cannot be nil/)
      end

      it "raises SignatureVerificationError for nil signature" do
        expect {
          described_class.verify!(
            payload: payload,
            signature: nil,
            timestamp: timestamp,
            secret: secret
          )
        }.to raise_error(Attio::Util::WebhookSignature::SignatureVerificationError, /Signature cannot be nil/)
      end

      it "raises SignatureVerificationError for empty signature" do
        expect {
          described_class.verify!(
            payload: payload,
            signature: "",
            timestamp: timestamp,
            secret: secret
          )
        }.to raise_error(Attio::Util::WebhookSignature::SignatureVerificationError, /Signature cannot be nil or empty/)
      end

      it "raises SignatureVerificationError for nil timestamp" do
        expect {
          described_class.verify!(
            payload: payload,
            signature: valid_signature,
            timestamp: nil,
            secret: secret
          )
        }.to raise_error(Attio::Util::WebhookSignature::SignatureVerificationError, /Timestamp cannot be nil/)
      end

      it "raises SignatureVerificationError for nil secret" do
        expect {
          described_class.verify!(
            payload: payload,
            signature: valid_signature,
            timestamp: timestamp,
            secret: nil
          )
        }.to raise_error(Attio::Util::WebhookSignature::SignatureVerificationError, /Secret cannot be nil/)
      end

      it "raises SignatureVerificationError for empty secret" do
        expect {
          described_class.verify!(
            payload: payload,
            signature: valid_signature,
            timestamp: timestamp,
            secret: ""
          )
        }.to raise_error(Attio::Util::WebhookSignature::SignatureVerificationError, /Secret cannot be nil or empty/)
      end
    end
  end

  describe ".verify" do
    it "returns true for valid signature" do
      expect(
        described_class.verify(
          payload: payload,
          signature: valid_signature,
          timestamp: timestamp,
          secret: secret
        )
      ).to be true
    end

    it "returns false for invalid signature" do
      expect(
        described_class.verify(
          payload: payload,
          signature: "v1=invalid",
          timestamp: timestamp,
          secret: secret
        )
      ).to be false
    end

    it "returns false for old timestamp" do
      old_timestamp = (Time.now.to_i - 400).to_s
      old_signature = described_class.calculate_signature(payload, old_timestamp, secret)

      expect(
        described_class.verify(
          payload: payload,
          signature: old_signature,
          timestamp: old_timestamp,
          secret: secret
        )
      ).to be false
    end
  end

  describe ".calculate_signature" do
    it "calculates correct signature for string payload" do
      signature = described_class.calculate_signature(payload, timestamp, secret)
      expected = "v1=#{OpenSSL::HMAC.hexdigest("SHA256", secret, "#{timestamp}.#{payload}")}"
      expect(signature).to eq(expected)
    end

    it "calculates correct signature for hash payload" do
      hash_payload = {event: "test", data: {id: 123}}
      signature = described_class.calculate_signature(hash_payload, timestamp, secret)
      json_payload = JSON.generate(hash_payload)
      expected = "v1=#{OpenSSL::HMAC.hexdigest("SHA256", secret, "#{timestamp}.#{json_payload}")}"
      expect(signature).to eq(expected)
    end
  end

  describe ".extract_from_headers" do
    context "with valid headers" do
      it "extracts signature and timestamp from lowercase headers" do
        headers = {
          "x-attio-signature" => "v1=abc123",
          "x-attio-timestamp" => "1234567890"
        }

        result = described_class.extract_from_headers(headers)
        expect(result[:signature]).to eq("v1=abc123")
        expect(result[:timestamp]).to eq("1234567890")
      end

      it "extracts from uppercase headers" do
        headers = {
          "X-ATTIO-SIGNATURE" => "v1=abc123",
          "X-ATTIO-TIMESTAMP" => "1234567890"
        }

        result = described_class.extract_from_headers(headers)
        expect(result[:signature]).to eq("v1=abc123")
        expect(result[:timestamp]).to eq("1234567890")
      end

      it "extracts from underscore headers" do
        headers = {
          "X_ATTIO_SIGNATURE" => "v1=abc123",
          "X_ATTIO_TIMESTAMP" => "1234567890"
        }

        result = described_class.extract_from_headers(headers)
        expect(result[:signature]).to eq("v1=abc123")
        expect(result[:timestamp]).to eq("1234567890")
      end
    end

    context "with missing headers" do
      it "raises error for missing signature" do
        headers = {"x-attio-timestamp" => "1234567890"}

        expect {
          described_class.extract_from_headers(headers)
        }.to raise_error(Attio::Util::WebhookSignature::SignatureVerificationError, /Missing signature header/)
      end

      it "raises error for missing timestamp" do
        headers = {"x-attio-signature" => "v1=abc123"}

        expect {
          described_class.extract_from_headers(headers)
        }.to raise_error(Attio::Util::WebhookSignature::SignatureVerificationError, /Missing timestamp header/)
      end
    end
  end

  describe "Handler" do
    let(:handler) { described_class::Handler.new(secret) }

    describe "#initialize" do
      it "accepts a valid secret" do
        expect(handler.secret).to eq(secret)
      end

      it "raises error for nil secret" do
        expect {
          described_class::Handler.new(nil)
        }.to raise_error(ArgumentError, /Webhook secret is required/)
      end

      it "raises error for empty secret" do
        expect {
          described_class::Handler.new("")
        }.to raise_error(ArgumentError, /Webhook secret is required/)
      end
    end

    describe "#verify_request" do
      let(:headers) do
        {
          "x-attio-signature" => valid_signature,
          "x-attio-timestamp" => timestamp
        }
      end

      context "with hash request" do
        it "verifies valid request" do
          request = {headers: headers, body: payload}
          expect(handler.verify_request(request)).to be true
        end

        it "raises error for invalid signature" do
          request = {
            headers: headers.merge("x-attio-signature" => "v1=invalid"),
            body: payload
          }

          expect {
            handler.verify_request(request)
          }.to raise_error(Attio::Util::WebhookSignature::SignatureVerificationError)
        end

        it "handles string keys" do
          request = {"headers" => headers, "body" => payload}
          expect(handler.verify_request(request)).to be true
        end

        it "handles missing headers hash" do
          request = {body: payload}
          expect {
            handler.verify_request(request)
          }.to raise_error(Attio::Util::WebhookSignature::SignatureVerificationError)
        end
      end

      context "with unsupported request type" do
        it "raises ArgumentError" do
          expect {
            handler.verify_request("string request")
          }.to raise_error(ArgumentError, /Unsupported request type/)
        end
      end

      context "with Rails-like request object" do
        it "works with ActionDispatch-style requests when Rails is present" do
          # This tests that IF Rails/ActionDispatch is available in the user's app,
          # our code will work with it. We're NOT requiring Rails.
          mock_request = double("ActionDispatch::Request",
            headers: {
              "x-attio-signature" => valid_signature,
              "x-attio-timestamp" => timestamp
            },
            raw_post: payload)

          # Temporarily stub the constant to simulate Rails environment
          stub_const("ActionDispatch::Request", Class.new)
          allow(mock_request).to receive(:is_a?).with(Hash).and_return(false)
          allow(mock_request).to receive(:is_a?).with(ActionDispatch::Request).and_return(true)

          expect(handler.verify_request(mock_request)).to be true
        end
      end

      context "with Rack request body extraction" do
        it "handles body extraction correctly" do
          rack_body = StringIO.new(payload)
          rack_request = double("rack_request",
            body: rack_body,
            env: {
              "HTTP_X_ATTIO_SIGNATURE" => valid_signature,
              "HTTP_X_ATTIO_TIMESTAMP" => timestamp
            })

          # Mock the type checks
          allow(rack_request).to receive(:is_a?).and_return(false)
          allow(rack_request).to receive(:is_a?).with(Hash).and_return(false)

          # Stub Rack::Request to make defined? work
          stub_const("Rack::Request", Class.new)
          allow(rack_request).to receive(:is_a?).with(Rack::Request).and_return(true)

          expect(handler.verify_request(rack_request)).to be true
        end
      end
    end

    describe "#parse_and_verify" do
      let(:json_payload) { '{"event":"test","data":{"id":123}}' }
      let(:headers) do
        signed_payload = "#{timestamp}.#{json_payload}"
        hmac = OpenSSL::HMAC.hexdigest("SHA256", secret, signed_payload)
        {
          "x-attio-signature" => "v1=#{hmac}",
          "x-attio-timestamp" => timestamp
        }
      end

      it "parses and returns JSON with symbols" do
        request = {headers: headers, body: json_payload}
        result = handler.parse_and_verify(request)

        expect(result).to eq({event: "test", data: {id: 123}})
      end

      it "raises error for invalid JSON" do
        request = {headers: headers, body: "invalid json {"}

        # Need to create valid signature for invalid JSON
        invalid_json = "invalid json {"
        signed_payload = "#{timestamp}.#{invalid_json}"
        hmac = OpenSSL::HMAC.hexdigest("SHA256", secret, signed_payload)
        request[:headers]["x-attio-signature"] = "v1=#{hmac}"

        expect {
          handler.parse_and_verify(request)
        }.to raise_error(Attio::Util::WebhookSignature::SignatureVerificationError, /Invalid JSON payload/)
      end

      it "raises error for invalid signature" do
        request = {
          headers: headers.merge("x-attio-signature" => "v1=invalid"),
          body: json_payload
        }

        expect {
          handler.parse_and_verify(request)
        }.to raise_error(Attio::Util::WebhookSignature::SignatureVerificationError)
      end
    end
  end
end
