# frozen_string_literal: true

require "spec_helper"

RSpec.describe Attio::WebhookUtils::SignatureVerifier do
  let(:secret) { "webhook_secret_123" }
  let(:verifier) { described_class.new(secret) }
  let(:payload) { '{"event":"record.created","data":{"id":"rec_123"}}' }
  let(:timestamp) { Time.now.to_i }

  describe "#initialize" do
    it "stores the secret" do
      expect(verifier.instance_variable_get(:@secret)).to eq(secret)
    end
  end

  describe "#verify" do
    context "with valid signature" do
      it "returns true for a valid signature" do
        signed_payload = "#{timestamp}.#{payload}"
        expected_signature = OpenSSL::HMAC.hexdigest("SHA256", secret, signed_payload)
        signature_header = "t=#{timestamp} v1=#{expected_signature}"

        expect(verifier.verify(payload, signature_header)).to be true
      end

      it "handles comma-separated header format" do
        signed_payload = "#{timestamp}.#{payload}"
        expected_signature = OpenSSL::HMAC.hexdigest("SHA256", secret, signed_payload)
        signature_header = "t=#{timestamp},v1=#{expected_signature}"

        expect(verifier.verify(payload, signature_header)).to be true
      end

      it "handles mixed separators in header" do
        signed_payload = "#{timestamp}.#{payload}"
        expected_signature = OpenSSL::HMAC.hexdigest("SHA256", secret, signed_payload)
        signature_header = "t=#{timestamp}, v1=#{expected_signature}"

        expect(verifier.verify(payload, signature_header)).to be true
      end

      it "accepts signatures within tolerance window" do
        old_timestamp = timestamp - 299 # Just under 5 minutes
        signed_payload = "#{old_timestamp}.#{payload}"
        expected_signature = OpenSSL::HMAC.hexdigest("SHA256", secret, signed_payload)
        signature_header = "t=#{old_timestamp} v1=#{expected_signature}"

        expect(verifier.verify(payload, signature_header)).to be true
      end

      it "accepts custom tolerance" do
        old_timestamp = timestamp - 600 # 10 minutes
        signed_payload = "#{old_timestamp}.#{payload}"
        expected_signature = OpenSSL::HMAC.hexdigest("SHA256", secret, signed_payload)
        signature_header = "t=#{old_timestamp} v1=#{expected_signature}"

        expect(verifier.verify(payload, signature_header, tolerance: 700)).to be true
      end
    end

    context "with invalid signature" do
      it "returns false for invalid signature" do
        signature_header = "t=#{timestamp} v1=invalid_signature"
        expect(verifier.verify(payload, signature_header)).to be false
      end

      it "returns false for nil signature header" do
        expect(verifier.verify(payload, nil)).to be false
      end

      it "returns false for empty signature header" do
        expect(verifier.verify(payload, "")).to be false
      end

      it "returns false for missing timestamp" do
        expected_signature = OpenSSL::HMAC.hexdigest("SHA256", secret, "#{timestamp}.#{payload}")
        signature_header = "v1=#{expected_signature}"
        expect(verifier.verify(payload, signature_header)).to be false
      end

      it "returns false for missing signature" do
        signature_header = "t=#{timestamp}"
        expect(verifier.verify(payload, signature_header)).to be false
      end

      it "returns false for signatures outside tolerance window" do
        old_timestamp = timestamp - 301 # Just over 5 minutes
        signed_payload = "#{old_timestamp}.#{payload}"
        expected_signature = OpenSSL::HMAC.hexdigest("SHA256", secret, signed_payload)
        signature_header = "t=#{old_timestamp} v1=#{expected_signature}"

        expect(verifier.verify(payload, signature_header)).to be false
      end

      it "returns false for future timestamps outside tolerance" do
        future_timestamp = timestamp + 301 # Future by more than 5 minutes
        signed_payload = "#{future_timestamp}.#{payload}"
        expected_signature = OpenSSL::HMAC.hexdigest("SHA256", secret, signed_payload)
        signature_header = "t=#{future_timestamp} v1=#{expected_signature}"

        expect(verifier.verify(payload, signature_header)).to be false
      end

      it "returns false for malformed header" do
        signature_header = "invalid_format"
        expect(verifier.verify(payload, signature_header)).to be false
      end

      it "returns false for tampered payload" do
        signed_payload = "#{timestamp}.#{payload}"
        expected_signature = OpenSSL::HMAC.hexdigest("SHA256", secret, signed_payload)
        signature_header = "t=#{timestamp} v1=#{expected_signature}"

        tampered_payload = '{"event":"record.created","data":{"id":"rec_456"}}'
        expect(verifier.verify(tampered_payload, signature_header)).to be false
      end

      it "returns false for wrong secret" do
        wrong_verifier = described_class.new("wrong_secret")
        signed_payload = "#{timestamp}.#{payload}"
        expected_signature = OpenSSL::HMAC.hexdigest("SHA256", secret, signed_payload)
        signature_header = "t=#{timestamp} v1=#{expected_signature}"

        expect(wrong_verifier.verify(payload, signature_header)).to be false
      end
    end

    context "with edge cases" do
      it "handles payload with special characters" do
        special_payload = '{"data":"test\n\r\t"}'
        signed_payload = "#{timestamp}.#{special_payload}"
        expected_signature = OpenSSL::HMAC.hexdigest("SHA256", secret, signed_payload)
        signature_header = "t=#{timestamp} v1=#{expected_signature}"

        expect(verifier.verify(special_payload, signature_header)).to be true
      end

      it "handles empty payload" do
        empty_payload = ""
        signed_payload = "#{timestamp}.#{empty_payload}"
        expected_signature = OpenSSL::HMAC.hexdigest("SHA256", secret, signed_payload)
        signature_header = "t=#{timestamp} v1=#{expected_signature}"

        expect(verifier.verify(empty_payload, signature_header)).to be true
      end

      it "handles header with extra fields" do
        signed_payload = "#{timestamp}.#{payload}"
        expected_signature = OpenSSL::HMAC.hexdigest("SHA256", secret, signed_payload)
        signature_header = "t=#{timestamp} v1=#{expected_signature} v2=ignored extra=data"

        expect(verifier.verify(payload, signature_header)).to be true
      end

      it "handles header with equals in value" do
        signed_payload = "#{timestamp}.#{payload}"
        expected_signature = OpenSSL::HMAC.hexdigest("SHA256", secret, signed_payload)
        # This tests the split("=", 2) logic
        signature_header = "t=#{timestamp} v1=#{expected_signature} extra=key=value"

        expect(verifier.verify(payload, signature_header)).to be true
      end
    end

    context "with secure comparison" do
      it "prevents timing attacks by comparing all bytes" do
        # Create two signatures of same length but different content
        sig1 = "a" * 64
        sig2 = "b" * 64

        # Both should fail but take similar time
        header1 = "t=#{timestamp} v1=#{sig1}"
        header2 = "t=#{timestamp} v1=#{sig2}"

        expect(verifier.verify(payload, header1)).to be false
        expect(verifier.verify(payload, header2)).to be false
      end

      it "returns false for signatures of different lengths" do
        short_sig = "short"
        long_sig = "a" * 100

        header1 = "t=#{timestamp} v1=#{short_sig}"
        header2 = "t=#{timestamp} v1=#{long_sig}"

        expect(verifier.verify(payload, header1)).to be false
        expect(verifier.verify(payload, header2)).to be false
      end
    end
  end

  describe "TOLERANCE constant" do
    it "is set to 300 seconds (5 minutes)" do
      expect(described_class::TOLERANCE).to eq(300)
    end
  end

  describe "integration scenarios" do
    it "verifies a realistic webhook payload" do
      realistic_payload = {
        event: "record.created",
        data: {
          id: {record_id: "rec_123"},
          object: "people",
          values: {
            name: [{first_name: "John", last_name: "Doe"}],
            email_addresses: ["john@example.com"]
          }
        },
        timestamp: timestamp
      }.to_json

      signed_payload = "#{timestamp}.#{realistic_payload}"
      expected_signature = OpenSSL::HMAC.hexdigest("SHA256", secret, signed_payload)
      signature_header = "t=#{timestamp} v1=#{expected_signature}"

      expect(verifier.verify(realistic_payload, signature_header)).to be true
    end

    it "handles webhook retry with same timestamp" do
      # Simulating a webhook retry that arrives 4 minutes later
      old_timestamp = timestamp - 240
      signed_payload = "#{old_timestamp}.#{payload}"
      expected_signature = OpenSSL::HMAC.hexdigest("SHA256", secret, signed_payload)
      signature_header = "t=#{old_timestamp} v1=#{expected_signature}"

      # Should still accept it as it's within tolerance
      expect(verifier.verify(payload, signature_header)).to be true
    end
  end
end
