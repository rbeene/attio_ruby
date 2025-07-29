# frozen_string_literal: true

require "openssl"

module Attio
  module WebhookUtils
    # Verifies webhook signatures to ensure payloads are from Attio
    class SignatureVerifier
      TOLERANCE = 300 # 5 minutes in seconds

      def initialize(secret)
        @secret = secret
      end

      # Verify the webhook signature
      # @param payload [String] The raw request body
      # @param signature_header [String] The signature header from the request
      # @param tolerance [Integer] Maximum age of timestamp in seconds
      # @return [Boolean] True if signature is valid
      def verify(payload, signature_header, tolerance: TOLERANCE)
        timestamp, signature = parse_signature_header(signature_header)
        return false unless timestamp && signature

        # Check timestamp tolerance
        current_time = Time.now.to_i
        if (current_time - timestamp.to_i).abs > tolerance
          return false
        end

        # Generate expected signature
        signed_payload = "#{timestamp}.#{payload}"
        expected_signature = OpenSSL::HMAC.hexdigest("SHA256", @secret, signed_payload)

        # Compare signatures securely
        secure_compare(signature, expected_signature)
      end

      private

      # Parse the signature header format: "t=timestamp v1=signature"
      def parse_signature_header(header)
        return [nil, nil] unless header

        timestamp = nil
        signature = nil

        header.split(/[,\s]+/).each do |element|
          key, value = element.split("=", 2)
          case key
          when "t"
            timestamp = value
          when "v1"
            signature = value
          end
        end

        [timestamp, signature]
      end

      # Secure string comparison to prevent timing attacks
      def secure_compare(a, b)
        return false unless a.bytesize == b.bytesize

        l = a.unpack("C*")
        r = b.unpack("C*")
        result = 0

        l.zip(r) { |x, y| result |= x ^ y }
        result == 0
      end
    end
  end
end
