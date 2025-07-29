# frozen_string_literal: true

# Helper methods for integration tests that run against the real Attio API
module IntegrationHelpers
  # Skip integration tests if API key is not present
  def skip_unless_integration_enabled
    unless ENV["RUN_INTEGRATION_TESTS"] == "true"
      skip "Integration tests are disabled. Set RUN_INTEGRATION_TESTS=true to run them."
    end

    unless ENV["ATTIO_API_KEY"]
      skip "Integration tests require ATTIO_API_KEY environment variable"
    end
  end

  # Generate unique test data to avoid conflicts
  def unique_email
    "test-#{SecureRandom.hex(8)}@example.com"
  end

  def unique_name(prefix = "Test")
    "#{prefix} #{SecureRandom.hex(8)}"
  end

  # Track created resources for cleanup
  def track_resource(type, id, additional_data = {})
    @created_resources ||= []
    @created_resources << {type: type, id: id, **additional_data}
  end

  # Clean up all tracked resources
  def cleanup_resources
    return unless @created_resources

    @created_resources.reverse_each do |resource|
      cleanup_resource(resource)
    rescue => e
      warn "Failed to cleanup #{resource[:type]} #{resource[:id]}: #{e.message}"
    end

    @created_resources.clear
  end

  private

  def cleanup_resource(resource)
    case resource[:type]
    when :person
      record = Attio::Person.retrieve(resource[:id])
      record.destroy
    when :company
      record = Attio::Company.retrieve(resource[:id])
      record.destroy
    when :note
      note = Attio::Note.retrieve(resource[:id])
      note.destroy
    when :task
      task = Attio::Task.retrieve(resource[:id])
      task.destroy
    when :list
      list = Attio::List.retrieve(resource[:id])
      list.destroy
    when :webhook
      webhook = Attio::Webhook.retrieve(resource[:id])
      webhook.destroy
    when :entry
      entry = Attio::Entry.retrieve(list: resource[:list_id], entry_id: resource[:id])
      entry.destroy
    end
  end

  # Rate limiting helper
  def with_rate_limit_retry(max_retries = 3)
    retries = 0
    begin
      yield
    rescue Attio::RateLimitError => e
      if retries < max_retries
        retries += 1
        sleep_time = e.retry_after || (2**retries)
        warn "Rate limited. Sleeping for #{sleep_time} seconds..."
        sleep sleep_time
        retry
      else
        raise
      end
    end
  end

  # Helper to ensure test data is unique
  def ensure_unique_email(base_email = nil)
    base_email ||= "test@example.com"
    domain = base_email.split("@").last
    "test-#{Time.now.to_i}-#{SecureRandom.hex(4)}@#{domain}"
  end

  # Helper to create test person with tracking
  def create_test_person(email: nil, first_name: nil, last_name: nil, **extra_values)
    email ||= ensure_unique_email
    first_name ||= "Test"
    last_name ||= unique_name("Person")

    person = Attio::Person.create(
      first_name: first_name,
      last_name: last_name,
      email: email,
      **extra_values
    )

    track_resource(:person, person.id)
    person
  end

  # Helper to create test company with tracking
  def create_test_company(name: nil, domain: nil, **extra_values)
    name ||= unique_name("Company")
    domain ||= "#{SecureRandom.hex(8)}.example.com"

    company = Attio::Company.create(
      name: name,
      domain: domain,
      **extra_values
    )

    track_resource(:company, company.id)
    company
  end
end

RSpec.configure do |config|
  config.include IntegrationHelpers, :integration

  config.before(:each, :integration) do
    skip_unless_integration_enabled

    # Configure Attio with real API key
    Attio.configure do |attio_config|
      attio_config.api_key = ENV["ATTIO_API_KEY"]
    end
  end

  config.after(:each, :integration) do
    # Clean up any resources created during the test
    cleanup_resources
  end
end
