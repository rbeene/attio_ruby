# frozen_string_literal: true

require "spec_helper"

RSpec.describe Attio::Error do
  let(:response) do
    {
      status: 400,
      body: {error: "Bad request"},
      headers: {"x-request-id" => "req_123"}
    }
  end

  describe "#initialize" do
    it "sets basic attributes" do
      error = described_class.new("Test error")
      expect(error.message).to eq("Test error")
      expect(error.response).to be_nil
      expect(error.code).to be_nil
      expect(error.request_id).to be_nil
    end

    it "extracts information from response" do
      error = described_class.new("Test error", response)
      expect(error.message).to eq("Test error: Bad request")
      expect(error.response).to eq(response)
      expect(error.code).to eq(400)
      expect(error.request_id).to eq("req_123")
    end

    it "handles response with message key" do
      response_with_message = response.merge(
        body: {message: "Something went wrong"}
      )
      error = described_class.new("Test error", response_with_message)
      expect(error.message).to eq("Test error: Something went wrong")
    end

    it "handles response without error message" do
      response_without_message = response.merge(body: {data: "some data"})
      error = described_class.new("Test error", response_without_message)
      expect(error.message).to eq("Test error")
    end

    it "handles non-hash body" do
      response_with_string_body = response.merge(body: "Error string")
      error = described_class.new("Test error", response_with_string_body)
      expect(error.message).to eq("Test error")
    end

    it "handles different case request ID headers" do
      response_uppercase = response.merge(
        headers: {"X-Request-Id" => "req_456"}
      )
      error = described_class.new("Test error", response_uppercase)
      expect(error.request_id).to eq("req_456")
    end

    it "handles missing headers" do
      response_no_headers = {status: 400, body: {}}
      error = described_class.new("Test error", response_no_headers)
      expect(error.request_id).to be_nil
    end
  end
end

RSpec.describe Attio::RateLimitError do
  let(:response) do
    {
      status: 429,
      body: {error: "Rate limit exceeded"},
      headers: {
        "x-request-id" => "req_123",
        "retry-after" => "60"
      }
    }
  end

  describe "#initialize" do
    it "extracts retry_after from headers" do
      error = described_class.new("Rate limited", response)
      expect(error.retry_after).to eq(60)
    end

    it "handles Retry-After with different case" do
      response_uppercase = response.merge(
        headers: {"Retry-After" => "120"}
      )
      error = described_class.new("Rate limited", response_uppercase)
      expect(error.retry_after).to eq(120)
    end

    it "handles missing retry-after header" do
      response_no_retry = response.merge(headers: {})
      error = described_class.new("Rate limited", response_no_retry)
      expect(error.retry_after).to be_nil
    end

    it "handles non-numeric retry-after" do
      response_invalid_retry = response.merge(
        headers: {"retry-after" => "invalid"}
      )
      error = described_class.new("Rate limited", response_invalid_retry)
      expect(error.retry_after).to eq(0)
    end
  end
end

RSpec.describe Attio::ErrorFactory do
  describe ".from_response" do
    it "creates BadRequestError for 400" do
      response = {status: 400, body: {}, headers: {}}
      error = described_class.from_response(response)
      expect(error).to be_a(Attio::BadRequestError)
    end

    it "creates AuthenticationError for 401" do
      response = {status: 401, body: {}, headers: {}}
      error = described_class.from_response(response)
      expect(error).to be_a(Attio::AuthenticationError)
    end

    it "creates ForbiddenError for 403" do
      response = {status: 403, body: {}, headers: {}}
      error = described_class.from_response(response)
      expect(error).to be_a(Attio::ForbiddenError)
    end

    it "creates NotFoundError for 404" do
      response = {status: 404, body: {}, headers: {}}
      error = described_class.from_response(response)
      expect(error).to be_a(Attio::NotFoundError)
    end

    it "creates ConflictError for 409" do
      response = {status: 409, body: {}, headers: {}}
      error = described_class.from_response(response)
      expect(error).to be_a(Attio::ConflictError)
    end

    it "creates UnprocessableEntityError for 422" do
      response = {status: 422, body: {}, headers: {}}
      error = described_class.from_response(response)
      expect(error).to be_a(Attio::UnprocessableEntityError)
    end

    it "creates RateLimitError for 429" do
      response = {status: 429, body: {}, headers: {}}
      error = described_class.from_response(response)
      expect(error).to be_a(Attio::RateLimitError)
    end

    it "creates generic ClientError for other 4xx" do
      response = {status: 405, body: {}, headers: {}}
      error = described_class.from_response(response)
      expect(error).to be_a(Attio::ClientError)
      expect(error).not_to be_a(Attio::BadRequestError)
    end

    it "creates ServerError for 5xx" do
      response = {status: 500, body: {}, headers: {}}
      error = described_class.from_response(response)
      expect(error).to be_a(Attio::ServerError)
    end

    it "creates generic Error for other status codes" do
      response = {status: 301, body: {}, headers: {}}
      error = described_class.from_response(response)
      expect(error).to be_a(Attio::Error)
      expect(error).not_to be_a(Attio::ClientError)
      expect(error).not_to be_a(Attio::ServerError)
    end

    it "uses custom message if provided" do
      response = {status: 404, body: {}, headers: {}}
      error = described_class.from_response(response, "Custom message")
      expect(error.message).to include("Custom message")
    end

    it "generates default message if not provided" do
      response = {status: 418, body: {}, headers: {}}
      error = described_class.from_response(response)
      expect(error.message).to eq("API request failed with status 418")
    end
  end

  describe ".from_exception" do
    it "creates TimeoutError for Faraday::TimeoutError" do
      exception = Faraday::TimeoutError.new("Connection timeout")
      error = described_class.from_exception(exception)
      expect(error).to be_a(Attio::TimeoutError)
      expect(error.message).to eq("Request timed out: Connection timeout")
    end

    it "creates TimeoutError for Net::ReadTimeout" do
      exception = Net::ReadTimeout.new("Read timeout")
      error = described_class.from_exception(exception)
      expect(error).to be_a(Attio::TimeoutError)
    end

    it "creates TimeoutError for Net::OpenTimeout" do
      exception = Net::OpenTimeout.new("Open timeout")
      error = described_class.from_exception(exception)
      expect(error).to be_a(Attio::TimeoutError)
    end

    it "creates NetworkError for Faraday::ConnectionFailed" do
      exception = Faraday::ConnectionFailed.new("Connection failed")
      error = described_class.from_exception(exception)
      expect(error).to be_a(Attio::NetworkError)
      expect(error.message).to eq("Network error: Connection failed")
    end

    it "creates NetworkError for SocketError" do
      exception = SocketError.new("Socket error")
      error = described_class.from_exception(exception)
      expect(error).to be_a(Attio::NetworkError)
    end

    it "creates NetworkError for Errno::ECONNREFUSED" do
      exception = Errno::ECONNREFUSED.new("Connection refused")
      error = described_class.from_exception(exception)
      expect(error).to be_a(Attio::NetworkError)
    end

    it "handles Faraday::ClientError" do
      # Create a real Faraday::ClientError with the necessary attributes
      faraday_response = double("response", status: 404, body: {error: "Not found"})
      client_error = Faraday::ClientError.new("Not found", faraday_response)

      # Stub the methods that ErrorFactory will call
      allow(client_error).to receive_messages(response_status: 404, response_body: {error: "Not found"})

      error = described_class.from_exception(client_error)
      expect(error).to be_a(Attio::NotFoundError)
    end

    it "creates generic ConnectionError for other exceptions" do
      exception = StandardError.new("Something went wrong")
      error = described_class.from_exception(exception)
      expect(error).to be_a(Attio::ConnectionError)
      expect(error.message).to eq("Connection error: Something went wrong")
    end

    it "accepts context parameter" do
      exception = StandardError.new("Error")
      # Context is currently unused but should be accepted
      expect {
        described_class.from_exception(exception, {url: "test"})
      }.not_to raise_error
    end
  end
end

RSpec.describe Attio::Error, "inheritance" do
  it "has proper inheritance hierarchy" do
    expect(Attio::ClientError.superclass).to eq(described_class)
    expect(Attio::ServerError.superclass).to eq(described_class)
    expect(Attio::ConnectionError.superclass).to eq(described_class)
    expect(Attio::ConfigurationError.superclass).to eq(described_class)

    expect(Attio::BadRequestError.superclass).to eq(Attio::ClientError)
    expect(Attio::AuthenticationError.superclass).to eq(Attio::ClientError)
    expect(Attio::ForbiddenError.superclass).to eq(Attio::ClientError)
    expect(Attio::NotFoundError.superclass).to eq(Attio::ClientError)
    expect(Attio::ConflictError.superclass).to eq(Attio::ClientError)
    expect(Attio::UnprocessableEntityError.superclass).to eq(Attio::ClientError)
    expect(Attio::RateLimitError.superclass).to eq(Attio::ClientError)
    expect(Attio::InvalidRequestError.superclass).to eq(Attio::ClientError)

    expect(Attio::TimeoutError.superclass).to eq(Attio::ConnectionError)
    expect(Attio::NetworkError.superclass).to eq(Attio::ConnectionError)
  end
end
