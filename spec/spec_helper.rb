# frozen_string_literal: true

require "attio"
require "pry"
require "vcr"
require "webmock/rspec"
require "dotenv/load"

# Load support files
Dir[File.join(__dir__, "support", "**", "*.rb")].sort.each { |f| require f }

# Configure VCR
VCR.configure do |config|
  config.cassette_library_dir = "spec/fixtures/vcr_cassettes"
  config.hook_into :faraday
  config.configure_rspec_metadata!
  
  # Filter sensitive data
  config.filter_sensitive_data('<ATTIO_API_KEY>') { ENV['ATTIO_API_KEY'] }
  config.filter_sensitive_data('<ATTIO_API_KEY>') { 'test_api_key' }
  
  # Allow real HTTP connections for recording
  config.allow_http_connections_when_no_cassette = false
  
  # Ignore OAuth requests (use WebMock for these)
  config.ignore_request do |request|
    URI(request.uri).path.include?('/oauth/')
  end
  
  # Default cassette options
  config.default_cassette_options = {
    record: :once,
    match_requests_on: [:method, :uri]
  }
end

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # Run specs in random order to surface order dependencies
  config.order = :random

  # Seed global randomization
  Kernel.srand config.seed

  # Clear configuration before each test
  config.before do
    Attio.reset!
    # Set a default test API key
    Attio.configure do |attio_config|
      attio_config.api_key = "test_api_key"
    end
  end

  # Filter run examples by tags
  config.filter_run_when_matching :focus
  config.filter_run_excluding :integration unless ENV["RUN_INTEGRATION_TESTS"]

  # Output formatting
  config.formatter = :documentation if ENV["CI"]
end
