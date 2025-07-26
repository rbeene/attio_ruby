# frozen_string_literal: true

require "attio"
require "pry"
require "dotenv/load"

# Load support files
Dir[File.join(__dir__, "support", "**", "*.rb")].sort.each { |f| require f }

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
  end

  # Filter run examples by tags
  config.filter_run_when_matching :focus
  config.filter_run_excluding :integration unless ENV["RUN_INTEGRATION_TESTS"]

  # Output formatting
  config.formatter = :documentation if ENV["CI"]
end
