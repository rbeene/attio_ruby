# frozen_string_literal: true

require "spec_helper"
require "faraday"

RSpec.describe Attio::Error do
  describe "#initialize" do
    it "creates an error with just a message" do
      error = described_class.new("Something went wrong")
      expect(error.message).to eq("Something went wrong")
      expect(error.response).to be_nil
      expect(error.code).to be_nil
      expect(error.request_id).to be_nil
    end

    it "creates an error with a response" do
      response = {
        status: 500,
        headers: {"x-request-id" => "req-123"},
        body: {error: "Internal server error"}
      }

      error = described_class.new("API error", response)
      expect(error.message).to eq("API error: Internal server error")
      expect(error.response).to eq(response)
      expect(error.code).to eq(500)
      expect(error.request_id).to eq("req-123")
    end

    it "handles response with message key instead of error" do
      response = {
        status: 400,
        body: {message: "Bad request"}
      }

      error = described_class.new("Request failed", response)
      expect(error.message).to eq("Request failed: Bad request")
    end

    it "handles response without error message in body" do
      response = {
        status: 404,
        body: {}
      }

      error = described_class.new("Not found", response)
      expect(error.message).to eq("Not found")
    end

    it "handles response with non-hash body" do
      response = {
        status: 500,
        body: "Server error"
      }

      error = described_class.new("API error", response)
      expect(error.message).to eq("API error")
    end

    it "extracts request ID with capital headers" do
      response = {
        headers: {"X-Request-Id" => "req-456"}
      }

      error = described_class.new("Error", response)
      expect(error.request_id).to eq("req-456")
    end

    it "handles missing headers" do
      response = {status: 500}

      error = described_class.new("Error", response)
      expect(error.request_id).to be_nil
    end
  end

  describe "RateLimitError" do
    describe "#initialize" do
      it "extracts retry-after header" do
        response = {
          status: 429,
          headers: {"retry-after" => "60"},
          body: {error: "Rate limit exceeded"}
        }

        error = Attio::RateLimitError.new("Rate limited", response)
        expect(error.message).to eq("Rate limited: Rate limit exceeded")
        expect(error.code).to eq(429)
        expect(error.retry_after).to eq(60)
      end

      it "handles capital Retry-After header" do
        response = {
          headers: {"Retry-After" => "120"}
        }

        error = Attio::RateLimitError.new("Rate limited", response)
        expect(error.retry_after).to eq(120)
      end

      it "handles missing retry-after header" do
        response = {
          status: 429,
          headers: {}
        }

        error = Attio::RateLimitError.new("Rate limited", response)
        expect(error.retry_after).to be_nil
      end

      it "handles non-numeric retry-after value" do
        response = {
          headers: {"retry-after" => "invalid"}
        }

        error = Attio::RateLimitError.new("Rate limited", response)
        expect(error.retry_after).to eq(0)
      end
    end
  end

  describe "ErrorFactory" do
    describe ".from_response" do
      it "creates BadRequestError for 400" do
        response = {status: 400}
        error = Attio::ErrorFactory.from_response(response)
        expect(error).to be_a(Attio::BadRequestError)
        expect(error.message).to eq("API request failed with status 400")
      end

      it "creates AuthenticationError for 401" do
        response = {status: 401}
        error = Attio::ErrorFactory.from_response(response)
        expect(error).to be_a(Attio::AuthenticationError)
      end

      it "creates ForbiddenError for 403" do
        response = {status: 403}
        error = Attio::ErrorFactory.from_response(response)
        expect(error).to be_a(Attio::ForbiddenError)
      end

      it "creates NotFoundError for 404" do
        response = {status: 404}
        error = Attio::ErrorFactory.from_response(response)
        expect(error).to be_a(Attio::NotFoundError)
      end

      it "creates ConflictError for 409" do
        response = {status: 409}
        error = Attio::ErrorFactory.from_response(response)
        expect(error).to be_a(Attio::ConflictError)
      end

      it "creates UnprocessableEntityError for 422" do
        response = {status: 422}
        error = Attio::ErrorFactory.from_response(response)
        expect(error).to be_a(Attio::UnprocessableEntityError)
      end

      it "creates RateLimitError for 429" do
        response = {status: 429, headers: {"retry-after" => "30"}}
        error = Attio::ErrorFactory.from_response(response)
        expect(error).to be_a(Attio::RateLimitError)
        expect(error.retry_after).to eq(30)
      end

      it "creates generic ClientError for other 4xx" do
        response = {status: 418}  # I'm a teapot
        error = Attio::ErrorFactory.from_response(response)
        expect(error).to be_a(Attio::ClientError)
        expect(error).not_to be_a(Attio::BadRequestError)
      end

      it "creates ServerError for 5xx" do
        response = {status: 500}
        error = Attio::ErrorFactory.from_response(response)
        expect(error).to be_a(Attio::ServerError)
      end

      it "creates ServerError for 503" do
        response = {status: 503}
        error = Attio::ErrorFactory.from_response(response)
        expect(error).to be_a(Attio::ServerError)
      end

      it "creates generic Error for non-standard status" do
        response = {status: 999}
        error = Attio::ErrorFactory.from_response(response)
        expect(error).to be_a(Attio::Error) # rubocop:disable RSpec/DescribedClass
        expect(error).not_to be_a(Attio::ClientError)
        expect(error).not_to be_a(Attio::ServerError)
      end

      it "uses custom message when provided" do
        response = {status: 404}
        error = Attio::ErrorFactory.from_response(response, "Resource not found")
        expect(error.message).to eq("Resource not found")
      end

      it "handles string status codes" do
        response = {status: "404"}
        error = Attio::ErrorFactory.from_response(response)
        expect(error).to be_a(Attio::NotFoundError)
      end
    end

    describe ".from_exception" do
      it "creates TimeoutError from Faraday::TimeoutError" do
        exception = Faraday::TimeoutError.new("Connection timed out")
        error = Attio::ErrorFactory.from_exception(exception)
        expect(error).to be_a(Attio::TimeoutError)
        expect(error.message).to eq("Request timed out: Connection timed out")
      end

      it "creates TimeoutError from Net::ReadTimeout" do
        exception = Net::ReadTimeout.new
        error = Attio::ErrorFactory.from_exception(exception)
        expect(error).to be_a(Attio::TimeoutError)
        expect(error.message).to include("Request timed out")
      end

      it "creates TimeoutError from Net::OpenTimeout" do
        exception = Net::OpenTimeout.new
        error = Attio::ErrorFactory.from_exception(exception)
        expect(error).to be_a(Attio::TimeoutError)
        expect(error.message).to include("Request timed out")
      end

      it "creates NetworkError from Faraday::ConnectionFailed" do
        exception = Faraday::ConnectionFailed.new("Connection refused")
        error = Attio::ErrorFactory.from_exception(exception)
        expect(error).to be_a(Attio::NetworkError)
        expect(error.message).to eq("Network error: Connection refused")
      end

      it "creates NetworkError from SocketError" do
        exception = SocketError.new("getaddrinfo: nodename nor servname provided")
        error = Attio::ErrorFactory.from_exception(exception)
        expect(error).to be_a(Attio::NetworkError)
        expect(error.message).to include("Network error")
      end

      it "creates NetworkError from Errno::ECONNREFUSED" do
        exception = Errno::ECONNREFUSED.new
        error = Attio::ErrorFactory.from_exception(exception)
        expect(error).to be_a(Attio::NetworkError)
        expect(error.message).to include("Network error")
      end

      it "creates appropriate error from Faraday::ClientError" do
        exception = Faraday::ClientError.new(StandardError.new, {status: 404, body: {error: "Not found"}})
        error = Attio::ErrorFactory.from_exception(exception)
        expect(error).to be_a(Attio::NotFoundError)
      end

      it "creates ConnectionError for unknown exceptions" do
        exception = StandardError.new("Unknown error")
        error = Attio::ErrorFactory.from_exception(exception)
        expect(error).to be_a(Attio::ConnectionError)
        expect(error.message).to eq("Connection error: Unknown error")
      end

      it "accepts context parameter" do
        exception = StandardError.new("Error")
        context = {operation: "test"}
        # Context is accepted but not used in current implementation
        error = Attio::ErrorFactory.from_exception(exception, context)
        expect(error).to be_a(Attio::ConnectionError)
      end
    end
  end

  # Test inheritance hierarchy
  describe "error inheritance" do
    it "ClientError inherits from Error" do
      expect(Attio::ClientError.new("test")).to be_a(Attio::Error) # rubocop:disable RSpec/DescribedClass
    end

    describe "client error inheritance" do
      it "BadRequestError inherits from ClientError" do
        expect(Attio::BadRequestError.new("test")).to be_a(Attio::ClientError)
      end

      it "AuthenticationError inherits from ClientError" do
        expect(Attio::AuthenticationError.new("test")).to be_a(Attio::ClientError)
      end

      it "ForbiddenError inherits from ClientError" do
        expect(Attio::ForbiddenError.new("test")).to be_a(Attio::ClientError)
      end

      it "NotFoundError inherits from ClientError" do
        expect(Attio::NotFoundError.new("test")).to be_a(Attio::ClientError)
      end

      it "ConflictError inherits from ClientError" do
        expect(Attio::ConflictError.new("test")).to be_a(Attio::ClientError)
      end

      it "UnprocessableEntityError inherits from ClientError" do
        expect(Attio::UnprocessableEntityError.new("test")).to be_a(Attio::ClientError)
      end

      it "RateLimitError inherits from ClientError" do
        expect(Attio::RateLimitError.new("test")).to be_a(Attio::ClientError)
      end

      it "InvalidRequestError inherits from ClientError" do
        expect(Attio::InvalidRequestError.new("test")).to be_a(Attio::ClientError)
      end
    end

    it "ServerError inherits from Error" do
      expect(Attio::ServerError.new("test")).to be_a(Attio::Error) # rubocop:disable RSpec/DescribedClass
    end

    it "ConnectionError inherits from Error" do
      expect(Attio::ConnectionError.new("test")).to be_a(Attio::Error) # rubocop:disable RSpec/DescribedClass
    end

    it "specific connection errors inherit from ConnectionError" do
      expect(Attio::TimeoutError.new("test")).to be_a(Attio::ConnectionError)
      expect(Attio::NetworkError.new("test")).to be_a(Attio::ConnectionError)
    end

    it "ConfigurationError inherits from Error" do
      expect(Attio::ConfigurationError.new("test")).to be_a(Attio::Error) # rubocop:disable RSpec/DescribedClass
    end
  end
end
