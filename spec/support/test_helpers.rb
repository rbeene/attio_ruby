# frozen_string_literal: true

module TestHelpers
  # Generate a unique identifier for test resources to avoid conflicts
  def unique_test_id(prefix = "test")
    timestamp = Time.now.strftime("%Y%m%d%H%M%S")
    random = SecureRandom.hex(4)
    "#{prefix}_#{timestamp}_#{random}"
  end

  # Generate unique test names
  def unique_test_name(base_name)
    "#{base_name} #{unique_test_id}"
  end

  # VCR cassette options for tests that create resources
  def vcr_options_for_create
    {
      record: :new_episodes,
      match_requests_on: [:method, :uri, :body]
    }
  end
end

RSpec.configure do |config|
  config.include TestHelpers
end
