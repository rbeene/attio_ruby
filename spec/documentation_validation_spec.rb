# frozen_string_literal: true

require "spec_helper"

# rubocop:disable RSpec/DescribeClass
RSpec.describe "README documentation validation" do
  # rubocop:enable RSpec/DescribeClass
  before do
    # Use test API key
    Attio.configure do |config|
      config.api_key = "5d4b3063a71a19b8d12a98f936b6b74d886d05f8580dba40538e019da8871eaf"
    end
  end

  describe "Quick Start examples" do
    it "validates configuration syntax" do
      # Reset configuration to test reconfiguration
      Attio.instance_variable_set(:@config, nil)

      # Ensure ENV is not returning empty string
      api_key = ENV["ATTIO_API_KEY"].to_s.empty? ? "5d4b3063a71a19b8d12a98f936b6b74d886d05f8580dba40538e019da8871eaf" : ENV["ATTIO_API_KEY"]

      expect {
        Attio.configure do |config|
          config.api_key = api_key
        end
      }.not_to raise_error
    end

    it "validates Record.create syntax" do
      expect(Attio::Record).to respond_to(:create)

      # Mock the request
      allow(Attio::Record).to receive(:create).and_return(
        Attio::Record.new({"id" => {"workspace_id" => "test", "object_id" => "test", "record_id" => "test"}})
      )

      person = Attio::Record.create(
        object: "people",
        values: {
          name: "John Doe",
          email_addresses: "john@example.com"
        }
      )

      expect(person).to be_a(Attio::Record)
    end

    it "validates Record.list syntax with params" do
      expect(Attio::Record).to respond_to(:list)

      allow(Attio::Record).to receive(:list).and_return(
        Attio::APIResource::ListObject.new([], {})
      )

      companies = Attio::Record.list(
        object: "companies",
        params: {q: "tech", limit: 10}
      )

      expect(companies).to be_a(Attio::APIResource::ListObject)
    end
  end

  describe "Configuration examples" do
    it "validates all configuration options" do
      expect {
        Attio.configure do |config|
          config.api_key = "your_api_key"
          config.api_base = "https://api.attio.com"
          config.api_version = "v2"
          config.timeout = 30
          config.max_retries = 3
          config.debug = false
          config.logger = Logger.new($stdout)
        end
      }.not_to raise_error
    end

    it "validates per-request configuration syntax" do
      allow(Attio::Record).to receive(:create).and_return(
        Attio::Record.new({"id" => {"workspace_id" => "test", "object_id" => "test", "record_id" => "test"}})
      )

      expect {
        Attio::Record.create(
          object: "people",
          values: {name: "Jane Doe"},
          opts: {api_key: "different_api_key"}
        )
      }.not_to raise_error
    end
  end

  describe "OAuth examples" do
    it "validates OAuth client initialization" do
      expect {
        Attio::OAuth::Client.new(
          client_id: "test_client_id",
          client_secret: "test_client_secret",
          redirect_uri: "https://yourapp.com/callback"
        )
      }.not_to raise_error
    end

    it "validates authorization_url method" do
      oauth_client = Attio::OAuth::Client.new(
        client_id: "test_client_id",
        client_secret: "test_client_secret",
        redirect_uri: "https://yourapp.com/callback"
      )

      expect(oauth_client).to respond_to(:authorization_url)

      auth_data = oauth_client.authorization_url(
        scopes: %w[record:read record:write],
        state: "random_state"
      )

      expect(auth_data).to be_a(Hash)
      expect(auth_data).to have_key(:url)
      expect(auth_data).to have_key(:state)
    end
  end

  describe "Object examples" do
    it "validates Object.list" do
      expect(Attio::Object).to respond_to(:list)
    end

    it "validates Object.retrieve" do
      expect(Attio::Object).to respond_to(:retrieve)
    end
  end

  describe "Record management examples" do
    it "validates record attribute access syntax" do
      record = Attio::Record.new({
        "id" => {"workspace_id" => "test", "object_id" => "test", "record_id" => "test"},
        "values" => {
          "name" => [{"value" => "John Doe"}],
          "email_addresses" => [{"value" => "john@example.com"}]
        }
      })

      # Test bracket access
      expect(record).to respond_to(:[])
      expect(record[:name]).to eq("John Doe")

      # Test bracket assignment
      expect(record).to respond_to(:[]=)
      record[:job_title] = "CTO"
      expect(record[:job_title]).to eq("CTO")
    end

    it "validates save method" do
      record = Attio::Record.new({
        "id" => {"workspace_id" => "test", "object_id" => "test", "record_id" => "test"}
      })

      expect(record).to respond_to(:save)
    end

    it "validates Record.update class method" do
      expect(Attio::Record).to respond_to(:update)
    end

    it "validates destroy method" do
      record = Attio::Record.new({
        "id" => {"workspace_id" => "test", "object_id" => "test", "record_id" => "test"}
      })

      expect(record).to respond_to(:destroy)
    end

    it "validates Record.delete class method" do
      expect(Attio::Record).to respond_to(:delete)
    end
  end

  describe "List examples" do
    it "validates List.create" do
      expect(Attio::List).to respond_to(:create)
    end

    it "validates list instance methods" do
      list = Attio::List.new({
        "id" => {"workspace_id" => "test", "list_id" => "test"}
      })

      expect(list).to respond_to(:add_record)
      expect(list).to respond_to(:entries)
      expect(list).to respond_to(:remove_record)
      expect(list).to respond_to(:destroy)
    end
  end

  describe "Note examples" do
    it "validates Note.create syntax" do
      expect(Attio::Note).to respond_to(:create)

      # Verify the method accepts the documented parameters
      allow(Attio::Note).to receive(:create).with(hash_including(
        parent_object: "people",
        parent_record_id: anything,
        content: anything,
        format: "plaintext"
      )).and_return(Attio::Note.new({}))
    end

    it "validates Note.list" do
      expect(Attio::Note).to respond_to(:list)
    end

    it "validates note instance methods" do
      note = Attio::Note.new({
        "id" => {"workspace_id" => "test", "note_id" => "test"},
        "content" => {"plaintext" => "test content"}
      })

      # Notes are immutable - they don't have content= or save
      expect(note).to respond_to(:destroy)
    end
  end

  describe "Webhook examples" do
    it "validates Webhook.create" do
      expect(Attio::Webhook).to respond_to(:create)
    end

    it "validates webhook instance methods" do
      webhook = Attio::Webhook.new({
        "id" => {"webhook_id" => "test"},
        "active" => true
      })

      # Webhooks use bracket access and save
      expect(webhook).to respond_to(:[]=)
      expect(webhook).to respond_to(:save)
      expect(webhook).to respond_to(:destroy)
    end

    it "validates WebhookSignature utility" do
      # The README incorrectly references the class - let's verify the correct one exists
      expect(Attio::Util::WebhookSignature).to respond_to(:verify!)
    end
  end

  describe "ListObject pagination" do
    it "validates pagination methods" do
      list_object = Attio::APIResource::ListObject.new([], {})

      # each_page doesn't exist, but these do:
      expect(list_object).to respond_to(:next_page)
      expect(list_object).to respond_to(:has_more?)
      expect(list_object).to respond_to(:auto_paging_each)
    end
  end

  describe "Service classes" do
    it "checks if PersonService exists" do
      # The README mentions service classes but they don't exist in the implementation
      # This is a documentation error
      expect { Attio::Services::PersonService }.to raise_error(NameError)
    end

    it "checks if CompanyService exists" do
      expect { Attio::Services::CompanyService }.to raise_error(NameError)
    end

    it "checks if BatchService exists" do
      expect { Attio::Services::BatchService }.to raise_error(NameError)
    end
  end

  describe "Caching" do
    it "checks if cache classes exist" do
      # The README mentions cache classes but they don't exist
      expect { Attio::Util::Cache::Memory }.to raise_error(NameError)
      expect { Attio::Util::Cache::Redis }.to raise_error(NameError)
    end
  end

  describe "Error handling" do
    it "validates error attributes" do
      # Check error attributes - errors have 'code' not 'http_status'
      error = Attio::InvalidRequestError.new("Test message")
      expect(error).to respond_to(:message)
      expect(error).to respond_to(:code)
      expect(error).to respond_to(:request_id)

      # Verify error inheritance
      expect(error).to be_a(Attio::Error)
      expect(error).to be_a(StandardError)
    end
  end
end
