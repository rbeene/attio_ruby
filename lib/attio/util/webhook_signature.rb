# frozen_string_literal: true

require "openssl"
require "base64"
require "time"

module Attio
  module Util
    # Verifies webhook signatures from Attio to ensure authenticity
    class WebhookSignature
      # HTTP header containing the webhook signature
      SIGNATURE_HEADER = "x-attio-signature"
      # HTTP header containing the request timestamp
      TIMESTAMP_HEADER = "x-attio-timestamp"
      TOLERANCE_SECONDS = 300 # 5 minutes

      class << self
        # Verify webhook signature (raises exception on failure)
        def verify!(payload:, signature:, timestamp:, secret:, tolerance: TOLERANCE_SECONDS)
          validate_inputs!(payload, signature, timestamp, secret)

          # Check timestamp to prevent replay attacks
          verify_timestamp!(timestamp, tolerance)

          # Calculate expected signature
          expected_signature = calculate_signature(payload, timestamp, secret)

          # Constant-time comparison to prevent timing attacks
          raise SignatureVerificationError, "Invalid signature" unless secure_compare(signature, expected_signature)
        rescue => e
          raise SignatureVerificationError, "Webhook signature verification failed: #{e.message}"
        end

        # Verify webhook signature (returns boolean)
        def verify(payload:, signature:, timestamp:, secret:, tolerance: TOLERANCE_SECONDS)
          verify!(payload: payload, signature: signature, timestamp: timestamp, secret: secret, tolerance: tolerance)
          true
        rescue SignatureVerificationError
          false
        end

        # Calculate signature for a payload
        def calculate_signature(payload, timestamp, secret)
          # Ensure payload is a string
          payload_string = payload.is_a?(String) ? payload : JSON.generate(payload)

          # Create the signed payload
          signed_payload = "#{timestamp}.#{payload_string}"

          # Calculate HMAC
          hmac = OpenSSL::HMAC.hexdigest("SHA256", secret, signed_payload)

          # Return in the format Attio uses
          "v1=#{hmac}"
        end

        # Extract signature from headers
        def extract_from_headers(headers)
          signature = headers[SIGNATURE_HEADER] || headers[SIGNATURE_HEADER.upcase] || headers[SIGNATURE_HEADER.tr("-", "_").upcase]
          timestamp = headers[TIMESTAMP_HEADER] || headers[TIMESTAMP_HEADER.upcase] || headers[TIMESTAMP_HEADER.tr("-", "_").upcase]

          raise SignatureVerificationError, "Missing signature header: #{SIGNATURE_HEADER}" unless signature
          raise SignatureVerificationError, "Missing timestamp header: #{TIMESTAMP_HEADER}" unless timestamp

          {
            signature: signature,
            timestamp: timestamp
          }
        end

        private

        def validate_inputs!(payload, signature, timestamp, secret)
          raise ArgumentError, "Payload cannot be nil" if payload.nil?
          raise ArgumentError, "Signature cannot be nil or empty" if signature.nil? || signature.empty?
          raise ArgumentError, "Timestamp cannot be nil or empty" if timestamp.nil? || timestamp.to_s.empty?
          raise ArgumentError, "Secret cannot be nil or empty" if secret.nil? || secret.empty?
        end

        def verify_timestamp!(timestamp, tolerance)
          timestamp_int = timestamp.to_i
          current_time = Time.now.to_i

          if timestamp_int < (current_time - tolerance)
            raise SignatureVerificationError, "Timestamp too old"
          end

          if timestamp_int > (current_time + tolerance)
            raise SignatureVerificationError, "Timestamp too far in the future"
          end
        end

        def secure_compare(a, b)
          return false unless a.bytesize == b.bytesize

          # Use constant-time comparison
          res = 0
          a.bytes.zip(b.bytes) { |x, y| res |= x ^ y }
          res == 0
        end
      end

      # Helper class for webhook handlers
      class Handler
        attr_reader :secret

        def initialize(secret)
          @secret = secret
          validate_secret!
        end

        # Verify a request
        def verify_request(request)
          headers = extract_headers(request)
          body = extract_body(request)

          signature_data = WebhookSignature.extract_from_headers(headers)

          WebhookSignature.verify!(
            payload: body,
            signature: signature_data[:signature],
            timestamp: signature_data[:timestamp],
            secret: secret
          )
        end

        # Parse and verify a request
        def parse_and_verify(request)
          verify_request(request)

          body = extract_body(request)
          JSON.parse(body, symbolize_names: true)
        rescue JSON::ParserError => e
          raise SignatureVerificationError, "Invalid JSON payload: #{e.message}"
        end

        private

        def validate_secret!
          raise ArgumentError, "Webhook secret is required" if secret.nil? || secret.empty?
        end

        def extract_headers(request)
          case request
          when Hash
            request[:headers] || request["headers"] || {}
          when defined?(Rack::Request) && Rack::Request
            request.env.select { |k, _| k.start_with?("HTTP_") }.transform_keys { |k| k.sub(/^HTTP_/, "").downcase }
          when defined?(ActionDispatch::Request) && ActionDispatch::Request
            request.headers.to_h
          else
            raise ArgumentError, "Unsupported request type: #{request.class}"
          end
        end

        def extract_body(request)
          case request
          when Hash
            request[:body] || request["body"] || ""
          when defined?(Rack::Request) && Rack::Request
            request.body.rewind
            request.body.read
          when defined?(ActionDispatch::Request) && ActionDispatch::Request
            request.raw_post
          else
            raise ArgumentError, "Unsupported request type: #{request.class}"
          end
        end
      end

      # Raised when webhook signature verification fails
      class SignatureVerificationError < StandardError; end
    end
  end
end
