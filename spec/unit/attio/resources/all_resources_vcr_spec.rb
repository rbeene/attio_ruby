# frozen_string_literal: true

RSpec.describe Attio do
  before do
    described_class.configure do |config|
      config.api_key = ENV["ATTIO_API_KEY"] || "5d4b3063a71a19b8d12a98f936b6b74d886d05f8580dba40538e019da8871eaf"
    end
  end

  describe Attio::Object do
    it "lists objects", :vcr do
      VCR.use_cassette("object/list") do
        result = described_class.list
        expect(result).to be_a(Attio::APIResource::ListObject)
        expect(result.first).to be_a(described_class) if result.any?
      end
    end

    it "retrieves a specific object", :vcr do
      VCR.use_cassette("object/retrieve") do
        result = described_class.retrieve("people")
        expect(result).to be_a(described_class)
      end
    end
  end

  describe Attio::WorkspaceMember do
    it "lists workspace members", :vcr do
      VCR.use_cassette("workspace_member/list") do
        result = described_class.list
        expect(result).to be_a(Attio::APIResource::ListObject)
        expect(result.first).to be_a(described_class) if result.any?
      end
    end
  end

  describe Attio::List do
    it "lists lists", :vcr do
      VCR.use_cassette("list/list") do
        result = described_class.list
        expect(result).to be_a(Attio::APIResource::ListObject)
        expect(result.first).to be_a(described_class) if result.any?
      end
    end

    it "creates a new list", :vcr do
      VCR.use_cassette("list/create") do
        result = described_class.create({
          object: "people",
          name: "VCR Test List"
        })
        expect(result).to be_a(described_class)
        expect(result.persisted?).to be true
      end
    end
  end

  describe Attio::Webhook do
    it "lists webhooks", :vcr do
      VCR.use_cassette("webhook/list") do
        result = described_class.list
        expect(result).to be_a(Attio::APIResource::ListObject)
      end
    end

    it "attempts to create a new webhook (may fail with invalid URL)", :vcr do
      VCR.use_cassette("webhook/create") do
        # This test records the actual API response, which may be a 400 error
        # since example.com is not a valid webhook endpoint
        expect do
          described_class.create({
            target_url: "https://example.com/webhook/vcr",
            subscriptions: [{event_type: "record.created"}]
          })
        end.to raise_error(Attio::BadRequestError)
      end
    end
  end

  describe Attio::Attribute do
    it "lists attributes for an object", :vcr do
      VCR.use_cassette("attribute/list") do
        result = described_class.list({object: "people"})
        expect(result).to be_a(Attio::APIResource::ListObject)
        expect(result.first).to be_a(described_class) if result.any?
      end
    end

    it "creates a new attribute", :vcr do
      VCR.use_cassette("attribute/create") do
        result = described_class.create({
          object: "people",
          name: "VCR Test Field",
          type: "text",
          description: "A test field created by VCR"
        })
        expect(result).to be_a(described_class)
        expect(result.persisted?).to be true
      end
    end
  end

  describe Attio::Note do
    let(:record_id) { "0174bfac-74b9-41de-b757-c6fa2a68ab00" } # From VCR cassette

    # Note: Note listing with filtering by record would require custom implementation
    # For now, we test note creation which is the primary use case

    it "creates a new note", :vcr do
      VCR.use_cassette("note/create") do
        result = described_class.create({
          object: "people",
          record_id: record_id,
          title: "VCR Test Note",
          content: "This is a test note created by VCR",
          format: "plaintext"
        })
        expect(result).to be_a(described_class)
        expect(result.persisted?).to be true
      end
    end
  end
end
