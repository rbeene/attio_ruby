# frozen_string_literal: true

require "spec_helper"

RSpec.describe Attio::Util::WebhookSignature do
  let(:secret) { "webhook_secret_123" }
  let(:payload) { '{"event":"record.created","data":{"id":"rec_123"}}' }
  let(:timestamp) { Time.now.to_i.to_s }
  let(:valid_signature) do
    signed_payload = "#{timestamp}.#{payload}"
    hmac = OpenSSL::HMAC.hexdigest("SHA256", secret, signed_payload)
    "v1=#{hmac}"
  end

  describe ".verify!" do
    context "with valid signature" do
      it "verifies successfully" do
        expect {
          described_class.verify!(
            payload: payload,
            signature: valid_signature,
            timestamp: timestamp,
            secret: secret
          )
        }.not_to raise_error
      end

      it "accepts hash payload" do
        hash_payload = {"event" => "record.created", "data" => {"id" => "rec_123"}}
        json_payload = JSON.generate(hash_payload)
        signed_payload = "#{timestamp}.#{json_payload}"
        hmac = OpenSSL::HMAC.hexdigest("SHA256", secret, signed_payload)
        signature = "v1=#{hmac}"

        expect {
          described_class.verify!(
            payload: hash_payload,
            signature: signature,
            timestamp: timestamp,
            secret: secret
          )
        }.not_to raise_error
      end

      it "accepts custom tolerance" do
        old_timestamp = (Time.now.to_i - 299).to_s
        signed_payload = "#{old_timestamp}.#{payload}"
        hmac = OpenSSL::HMAC.hexdigest("SHA256", secret, signed_payload)
        signature = "v1=#{hmac}"

        expect {
          described_class.verify!(
            payload: payload,
            signature: signature,
            timestamp: old_timestamp,
            secret: secret,
            tolerance: 300
          )
        }.not_to raise_error
      end
    end

    context "with invalid signature" do
      it "raises error for wrong signature" do
        expect {
          described_class.verify!(
            payload: payload,
            signature: "v1=invalid",
            timestamp: timestamp,
            secret: secret
          )
        }.to raise_error(Attio::Util::WebhookSignature::SignatureVerificationError)
      end

      it "raises error for old timestamp" do
        old_timestamp = (Time.now.to_i - 301).to_s
        signed_payload = "#{old_timestamp}.#{payload}"
        hmac = OpenSSL::HMAC.hexdigest("SHA256", secret, signed_payload)
        signature = "v1=#{hmac}"

        expect {
          described_class.verify!(
            payload: payload,
            signature: signature,
            timestamp: old_timestamp,
            secret: secret
          )
        }.to raise_error(Attio::Util::WebhookSignature::SignatureVerificationError, /Timestamp too old/)
      end

      it "raises error for future timestamp" do
        future_timestamp = (Time.now.to_i + 301).to_s
        signed_payload = "#{future_timestamp}.#{payload}"
        hmac = OpenSSL::HMAC.hexdigest("SHA256", secret, signed_payload)
        signature = "v1=#{hmac}"

        expect {
          described_class.verify!(
            payload: payload,
            signature: signature,
            timestamp: future_timestamp,
            secret: secret
          )
        }.to raise_error(Attio::Util::WebhookSignature::SignatureVerificationError, /Timestamp too far in the future/)
      end

      it "raises error for nil payload" do
        expect {
          described_class.verify!(
            payload: nil,
            signature: valid_signature,
            timestamp: timestamp,
            secret: secret
          )
        }.to raise_error(Attio::Util::WebhookSignature::SignatureVerificationError, /Payload cannot be nil/)
      end

      it "raises error for nil signature" do
        expect {
          described_class.verify!(
            payload: payload,
            signature: nil,
            timestamp: timestamp,
            secret: secret
          )
        }.to raise_error(Attio::Util::WebhookSignature::SignatureVerificationError, /Signature cannot be nil or empty/)
      end

      it "raises error for empty signature" do
        expect {
          described_class.verify!(
            payload: payload,
            signature: "",
            timestamp: timestamp,
            secret: secret
          )
        }.to raise_error(Attio::Util::WebhookSignature::SignatureVerificationError, /Signature cannot be nil or empty/)
      end

      it "raises error for nil timestamp" do
        expect {
          described_class.verify!(
            payload: payload,
            signature: valid_signature,
            timestamp: nil,
            secret: secret
          )
        }.to raise_error(Attio::Util::WebhookSignature::SignatureVerificationError, /Timestamp cannot be nil or empty/)
      end

      it "raises error for nil secret" do
        expect {
          described_class.verify!(
            payload: payload,
            signature: valid_signature,
            timestamp: timestamp,
            secret: nil
          )
        }.to raise_error(Attio::Util::WebhookSignature::SignatureVerificationError, /Secret cannot be nil or empty/)
      end

      it "raises error for empty secret" do
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
      result = described_class.verify(
        payload: payload,
        signature: valid_signature,
        timestamp: timestamp,
        secret: secret
      )
      expect(result).to be true
    end

    it "returns false for invalid signature" do
      result = described_class.verify(
        payload: payload,
        signature: "v1=invalid",
        timestamp: timestamp,
        secret: secret
      )
      expect(result).to be false
    end

    it "returns false for signature verification errors" do
      result = described_class.verify(
        payload: nil,
        signature: valid_signature,
        timestamp: timestamp,
        secret: secret
      )
      expect(result).to be false
    end
  end

  describe ".calculate_signature" do
    it "calculates correct signature for string payload" do
      signature = described_class.calculate_signature(payload, timestamp, secret)
      expect(signature).to eq(valid_signature)
    end

    it "calculates correct signature for hash payload" do
      hash_payload = {"event" => "record.created", "data" => {"id" => "rec_123"}}
      signature = described_class.calculate_signature(hash_payload, timestamp, secret)

      # Verify it creates the same signature as JSON string
      json_payload = JSON.generate(hash_payload)
      expected_signature = described_class.calculate_signature(json_payload, timestamp, secret)

      expect(signature).to eq(expected_signature)
    end

    it "returns signature in v1= format" do
      signature = described_class.calculate_signature(payload, timestamp, secret)
      expect(signature).to start_with("v1=")
    end
  end

  describe ".extract_from_headers" do
    it "extracts signature and timestamp from headers" do
      headers = {
        "x-attio-signature" => "v1=abc123",
        "x-attio-timestamp" => "1234567890"
      }

      result = described_class.extract_from_headers(headers)
      expect(result).to eq({
        signature: "v1=abc123",
        timestamp: "1234567890"
      })
    end

    it "handles uppercase headers" do
      headers = {
        "X-ATTIO-SIGNATURE" => "v1=abc123",
        "X-ATTIO-TIMESTAMP" => "1234567890"
      }

      result = described_class.extract_from_headers(headers)
      expect(result).to eq({
        signature: "v1=abc123",
        timestamp: "1234567890"
      })
    end

    it "handles underscore headers" do
      headers = {
        "X_ATTIO_SIGNATURE" => "v1=abc123",
        "X_ATTIO_TIMESTAMP" => "1234567890"
      }

      result = described_class.extract_from_headers(headers)
      expect(result).to eq({
        signature: "v1=abc123",
        timestamp: "1234567890"
      })
    end

    it "raises error for missing signature header" do
      headers = {"x-attio-timestamp" => "1234567890"}

      expect {
        described_class.extract_from_headers(headers)
      }.to raise_error(
        Attio::Util::WebhookSignature::SignatureVerificationError,
        "Missing signature header: x-attio-signature"
      )
    end

    it "raises error for missing timestamp header" do
      headers = {"x-attio-signature" => "v1=abc123"}

      expect {
        described_class.extract_from_headers(headers)
      }.to raise_error(
        Attio::Util::WebhookSignature::SignatureVerificationError,
        "Missing timestamp header: x-attio-timestamp"
      )
    end
  end

  describe "Constants" do
    it "has correct header constants" do
      expect(described_class::SIGNATURE_HEADER).to eq("x-attio-signature")
      expect(described_class::TIMESTAMP_HEADER).to eq("x-attio-timestamp")
      expect(described_class::TOLERANCE_SECONDS).to eq(300)
    end
  end

  describe "::Handler" do
    let(:handler) { described_class::Handler.new(secret) }

    describe "#initialize" do
      it "stores the secret" do
        expect(handler.secret).to eq(secret)
      end

      it "raises error for nil secret" do
        expect {
          described_class::Handler.new(nil)
        }.to raise_error(ArgumentError, "Webhook secret is required")
      end

      it "raises error for empty secret" do
        expect {
          described_class::Handler.new("")
        }.to raise_error(ArgumentError, "Webhook secret is required")
      end
    end

    describe "#verify_request" do
      let(:request) do
        {
          headers: {
            "x-attio-signature" => valid_signature,
            "x-attio-timestamp" => timestamp
          },
          body: payload
        }
      end

      it "verifies valid request" do
        expect { handler.verify_request(request) }.not_to raise_error
      end

      it "raises error for invalid signature" do
        request[:headers]["x-attio-signature"] = "v1=invalid"

        expect {
          handler.verify_request(request)
        }.to raise_error(Attio::Util::WebhookSignature::SignatureVerificationError)
      end

      it "handles string keys in request" do
        string_request = {
          "headers" => {
            "x-attio-signature" => valid_signature,
            "x-attio-timestamp" => timestamp
          },
          "body" => payload
        }

        expect { handler.verify_request(string_request) }.not_to raise_error
      end
    end

    describe "#parse_and_verify" do
      let(:request) do
        {
          headers: {
            "x-attio-signature" => valid_signature,
            "x-attio-timestamp" => timestamp
          },
          body: payload
        }
      end

      it "verifies and parses valid request" do
        result = handler.parse_and_verify(request)
        expect(result).to eq({event: "record.created", data: {id: "rec_123"}})
      end

      it "raises error for invalid JSON" do
        request[:body] = "invalid json"

        # Need to recalculate signature for invalid JSON
        signed_payload = "#{timestamp}.invalid json"
        hmac = OpenSSL::HMAC.hexdigest("SHA256", secret, signed_payload)
        request[:headers]["x-attio-signature"] = "v1=#{hmac}"

        expect {
          handler.parse_and_verify(request)
        }.to raise_error(
          Attio::Util::WebhookSignature::SignatureVerificationError,
          /Invalid JSON payload/
        )
      end
    end

    describe "request extraction" do
      it "handles unsupported request types" do
        unsupported_request = Object.new

        expect {
          handler.verify_request(unsupported_request)
        }.to raise_error(ArgumentError, /Unsupported request type/)
      end

      it "handles missing headers in hash request" do
        request = {body: payload}

        expect {
          handler.verify_request(request)
        }.to raise_error(Attio::Util::WebhookSignature::SignatureVerificationError)
      end

      it "handles missing body in hash request" do
        request = {
          headers: {
            "x-attio-signature" => valid_signature,
            "x-attio-timestamp" => timestamp
          }
        }

        # Empty body should still verify if signature matches
        empty_signature = described_class.calculate_signature("", timestamp, secret)
        request[:headers]["x-attio-signature"] = empty_signature

        expect { handler.verify_request(request) }.not_to raise_error
      end
    end
  end

  describe "edge cases" do
    it "handles signatures of different lengths" do
      # The secure_compare should return false for different lengths
      # which will trigger the SignatureVerificationError
      result = described_class.verify(
        payload: payload,
        signature: "v1=short",
        timestamp: timestamp,
        secret: secret
      )
      expect(result).to be false
    end

    it "handles empty payload" do
      empty_payload = ""
      empty_signature = described_class.calculate_signature(empty_payload, timestamp, secret)

      result = described_class.verify(
        payload: empty_payload,
        signature: empty_signature,
        timestamp: timestamp,
        secret: secret
      )
      expect(result).to be true
    end

    it "provides wrapped error messages" do
      expect {
        described_class.verify!(
          payload: nil,
          signature: valid_signature,
          timestamp: timestamp,
          secret: secret
        )
      }.to raise_error(
        Attio::Util::WebhookSignature::SignatureVerificationError,
        /Webhook signature verification failed:/
      )
    end
  end
end
