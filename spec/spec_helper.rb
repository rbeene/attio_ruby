# frozen_string_literal: true

# Start SimpleCov before loading any application code
if ENV["COVERAGE"] == "true"
  require "simplecov"
  SimpleCov.start
end

require "attio"
require "pry"
require "webmock/rspec"
require "dotenv/load"

# Load support files
Dir[File.join(__dir__, "support", "**", "*.rb")].sort.each { |f| require f }

# Load integration helper for integration tests
require_relative "integration/integration_helper" if Dir.exist?(File.join(__dir__, "integration"))

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
  config.before do |example|
    Attio.reset!
    # Set a default test API key for unit tests only
    unless example.metadata[:integration]
      Attio.configure do |attio_config|
        attio_config.api_key = "test_api_key"
      end
    end
  end

  # Configure WebMock for integration tests
  config.before(:each, :integration) do
    if ENV["RUN_INTEGRATION_TESTS"] == "true" && ENV["ATTIO_API_KEY"]
      WebMock.allow_net_connect!
    end
  end

  config.after(:each, :integration) do
    WebMock.disable_net_connect!
  end

  # Filter run examples by tags
  config.filter_run_when_matching :focus
  config.filter_run_excluding :integration unless ENV["RUN_INTEGRATION_TESTS"]

  # Output formatting
  config.formatter = :documentation if ENV["CI"]
end
