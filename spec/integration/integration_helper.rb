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
    @created_resources << { type: type, id: id, **additional_data }
  end

  # Clean up all tracked resources
  def cleanup_resources
    return unless @created_resources

    @created_resources.reverse.each do |resource|
      cleanup_resource(resource)
    rescue => e
      warn "Failed to cleanup #{resource[:type]} #{resource[:id]}: #{e.message}"
    end

    @created_resources.clear
  end

  private

  def cleanup_resource(resource)
    case resource[:type]
    when :person, :company
      record = Attio::Record.retrieve(object: resource[:object] || "people", record_id: resource[:id])
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
        sleep_time = e.retry_after || (2 ** retries)
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
  def create_test_person(values = {})
    default_values = {
      name: unique_name("Person"),
      email_addresses: ensure_unique_email
    }
    
    person = Attio::Record.create(
      object: "people",
      values: default_values.merge(values)
    )
    
    track_resource(:person, person.id["record_id"], object: "people")
    person
  end

  # Helper to create test company with tracking
  def create_test_company(values = {})
    default_values = {
      name: unique_name("Company"),
      domains: ["#{SecureRandom.hex(8)}.example.com"]
    }
    
    company = Attio::Record.create(
      object: "companies",
      values: default_values.merge(values)
    )
    
    track_resource(:company, company.id["record_id"], object: "companies")
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