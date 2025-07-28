# frozen_string_literal: true

require "spec_helper"

RSpec.describe Attio::APIResource do
  describe "#save for creation" do
    shared_examples "creates new resource via save" do |resource_class, attributes, expected_create_params|
      let(:new_resource) { resource_class.new(attributes) }
      let(:created_resource) do
        resource_class.new(attributes.merge(
          "id" => {"#{resource_class.name.split("::").last.downcase}_id" => "created-123"},
          "created_at" => "2025-07-27T12:00:00Z"
        ))
      end

      before do
        allow(resource_class).to receive(:create).with(expected_create_params).and_return(created_resource)
      end

      it "creates the resource when not persisted" do
        expect(new_resource.persisted?).to be false
        result = new_resource.save
        expect(result).to eq(new_resource)
        expect(result.persisted?).to be true
        expect(result.id.values.any? { |v| v.to_s.include?("created-123") }).to be true
      end
    end

    describe "List" do
      include_examples "creates new resource via save",
        Attio::List,
        {"object" => "people", "name" => "Test List"},
        {object: "people", name: "Test List"}
    end

    describe "Task" do
      include_examples "creates new resource via save",
        Attio::Task,
        {"content" => "Complete the project", "deadline_at" => "2025-12-31T23:59:59Z"},
        {content: "Complete the project", format: "plaintext", deadline_at: "2025-12-31T23:59:59Z"}
    end

    describe "Record" do
      let(:new_record) do
        Attio::Record.new(
          "object_api_slug" => "people",
          "name" => "Test Person",
          "email_addresses" => "test@example.com"
        )
      end

      let(:created_record) do
        Attio::Record.new(
          "id" => {"workspace_id" => "ws_123", "object_id" => "obj_123", "record_id" => "created-record-123"},
          "object_api_slug" => "people",
          "name" => "Test Person",
          "email_addresses" => "test@example.com",
          "created_at" => "2025-07-27T12:00:00Z"
        )
      end

      before do
        allow(Attio::Record).to receive(:create).with(
          object: "people",
          values: {name: "Test Person", email_addresses: "test@example.com"}
        ).and_return(created_record)
      end

      it "creates with object context" do
        expect(new_record.persisted?).to be false
        result = new_record.save
        expect(result).to eq(new_record)
        expect(result.persisted?).to be true
        expect(result.id).to eq(created_record.id)
      end

      it "raises error without object context" do
        record_without_object = Attio::Record.new("name" => "Test")
        expect { record_without_object.save }.to raise_error(
          Attio::InvalidRequestError,
          /Cannot save a new record without object context/
        )
      end
    end

    describe "Webhook" do
      include_examples "creates new resource via save",
        Attio::Webhook,
        {
          "target_url" => "https://example.com/webhooks",
          "subscriptions" => [{"event_type" => "record.created"}]
        },
        {
          target_url: "https://example.com/webhooks",
          subscriptions: [{event_type: "record.created"}]
        }

      it "raises error without required attributes" do
        incomplete_webhook = Attio::Webhook.new("target_url" => "https://example.com")
        expect { incomplete_webhook.save }.to raise_error(
          Attio::InvalidRequestError,
          /Cannot save a new webhook without 'target_url' and 'subscriptions'/
        )
      end
    end

    describe "Attribute" do
      include_examples "creates new resource via save",
        Attio::Attribute,
        {
          "object" => "people",
          "name" => "Custom Field",
          "type" => "text"
        },
        {
          object: "people",
          name: "Custom Field",
          type: "text"
        }

      it "raises error without required attributes" do
        incomplete_attr = Attio::Attribute.new("name" => "Test")
        expect { incomplete_attr.save }.to raise_error(
          Attio::InvalidRequestError,
          /Cannot save a new attribute without 'object', 'name', and 'type'/
        )
      end
    end
  end
end
