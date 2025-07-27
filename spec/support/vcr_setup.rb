# frozen_string_literal: true

require "vcr"

# Only configure VCR for integration tests
if ENV["RUN_INTEGRATION_TESTS"]
  VCR.configure do |config|
    config.cassette_library_dir = "spec/fixtures/vcr_cassettes"
    config.hook_into :webmock
    config.configure_rspec_metadata!

    # Filter sensitive data
    config.filter_sensitive_data("<API_KEY>") { ENV["ATTIO_API_KEY"] }
    config.filter_sensitive_data("<CLIENT_ID>") { ENV["ATTIO_CLIENT_ID"] }
    config.filter_sensitive_data("<CLIENT_SECRET>") { ENV["ATTIO_CLIENT_SECRET"] }

    # Allow localhost connections (for testing webhooks)
    config.ignore_localhost = true

    # Default cassette options
    config.default_cassette_options = {
      record: :once,
      match_requests_on: %i[method uri body]
    }

    # Automatically name cassettes based on example description
    config.before_record do |interaction|
      # Remove request IDs and timestamps for consistent replay
      if interaction.response.headers["x-request-id"]
        interaction.response.headers["x-request-id"] = ["req_test"]
      end

      if interaction.request.headers["X-Request-Id"]
        interaction.request.headers["X-Request-Id"] = ["req_test"]
      end
    end
  end

  # Helper to use VCR with custom cassette name
  def with_vcr_cassette(name, options = {}, &)
    VCR.use_cassette(name, options, &)
  end
end
