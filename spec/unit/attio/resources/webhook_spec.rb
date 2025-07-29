# frozen_string_literal: true

require "spec_helper"

RSpec.describe Attio::Webhook do
  let(:webhook_attributes) do
    {
      id: {"webhook_id" => "webhook_123"},
      target_url: "https://example.com/webhook",
      subscriptions: [
        {
          "event_type" => "record.created",
          "filter" => {"$and" => []}
        }
      ],
      status: "active",
      secret: "webhook_secret_123",
      last_event_at: "2023-01-15T10:30:00Z",
      created_by_actor: {
        type: "user",
        id: "usr_123"
      }
    }
  end

  describe "#initialize" do
    it "sets attributes correctly" do
      webhook = described_class.new(webhook_attributes)

      expect(webhook.target_url).to eq("https://example.com/webhook")
      expect(webhook.subscriptions).to eq([{event_type: "record.created", filter: {"$and" => []}}])
      expect(webhook.status).to eq("active")
      expect(webhook.secret).to eq("webhook_secret_123")
      expect(webhook.last_event_at).to be_a(Time)
      expect(webhook.created_by_actor).to eq({type: "user", id: "usr_123"})
    end

    it "sets active based on status" do
      active_webhook = described_class.new(status: "active")
      expect(active_webhook.active).to be true

      paused_webhook = described_class.new(status: "paused")
      expect(paused_webhook.active).to be false
    end

    it "handles string keys" do
      string_attrs = {
        "id" => {"webhook_id" => "webhook_456"},
        "target_url" => "https://example.com/hook",
        "subscriptions" => [{"event_type" => "record.updated"}],
        "status" => "active"
      }

      webhook = described_class.new(string_attrs)
      expect(webhook.target_url).to eq("https://example.com/hook")
      expect(webhook.status).to eq("active")
    end

    it "parses last_event_at timestamp" do
      webhook = described_class.new(last_event_at: "2023-01-15T10:30:00Z")
      expect(webhook.last_event_at).to be_a(Time)
      expect(webhook.last_event_at.iso8601).to eq("2023-01-15T10:30:00Z")
    end
  end

  describe ".resource_path" do
    it "returns the correct path" do
      expect(described_class.resource_path).to eq("webhooks")
    end
  end

  describe "#resource_path" do
    it "returns the correct path for a persisted webhook" do
      webhook = described_class.new(webhook_attributes)
      expect(webhook.resource_path).to eq("webhooks/webhook_123")
    end

    it "extracts webhook_id from nested hash" do
      webhook = described_class.new(id: {"webhook_id" => "webhook_789"})
      expect(webhook.resource_path).to eq("webhooks/webhook_789")
    end

    it "handles simple ID format" do
      webhook = described_class.new(id: "webhook_simple")
      expect(webhook.resource_path).to eq("webhooks/webhook_simple")
    end

    it "raises error for unpersisted webhook" do
      webhook = described_class.new({})
      expect { webhook.resource_path }.to raise_error(
        Attio::InvalidRequestError,
        "Cannot generate path without an ID"
      )
    end
  end

  describe "#url and #url=" do
    it "aliases target_url" do
      webhook = described_class.new(target_url: "https://example.com/hook")
      expect(webhook.url).to eq("https://example.com/hook")

      webhook.url = "https://newurl.com/hook"
      expect(webhook.target_url).to eq("https://newurl.com/hook")
    end
  end

  describe "#active?" do
    it "returns true when active" do
      webhook = described_class.new(webhook_attributes)
      expect(webhook.active?).to be true
    end

    it "returns false when not active" do
      webhook = described_class.new(status: "paused")
      expect(webhook.active?).to be false
    end
  end

  describe "#paused?" do
    it "returns true when paused" do
      webhook = described_class.new(status: "paused")
      expect(webhook.paused?).to be true
    end

    it "returns false when active" do
      webhook = described_class.new(status: "active")
      expect(webhook.paused?).to be false
    end
  end

  describe "#pause" do
    let(:webhook) { described_class.new(webhook_attributes) }

    it "sets active to false and saves" do
      expect(webhook).to receive(:save)
      webhook.pause
      expect(webhook.active).to be false
    end

    it "passes options to save" do
      expect(webhook).to receive(:save).with(api_key: "custom_key")
      webhook.pause(api_key: "custom_key")
    end
  end

  describe "#resume" do
    let(:webhook) { described_class.new(webhook_attributes.merge(status: "paused")) }

    it "sets active to true and saves" do
      expect(webhook).to receive(:save)
      webhook.resume
      expect(webhook.active).to be true
    end

    it "aliases activate" do
      expect(webhook).to receive(:save)
      webhook.activate
      expect(webhook.active).to be true
    end
  end

  describe "#test" do
    let(:webhook) { described_class.new(webhook_attributes) }

    it "sends a test request" do
      expect(described_class).to receive(:execute_request).with(
        :POST,
        "webhooks/webhook_123/test",
        {},
        {}
      )

      result = webhook.test
      expect(result).to be true
    end

    it "raises error for unpersisted webhook" do
      unpersisted = described_class.new({})
      expect { unpersisted.test }.to raise_error(
        Attio::InvalidRequestError,
        "Cannot test a webhook without an ID"
      )
    end

    it "passes options" do
      expect(described_class).to receive(:execute_request).with(
        :POST,
        "webhooks/webhook_123/test",
        {},
        {api_key: "custom_key"}
      )

      webhook.test(api_key: "custom_key")
    end
  end

  describe "#deliveries" do
    let(:webhook) { described_class.new(webhook_attributes) }

    it "fetches deliveries for the webhook" do
      deliveries_data = [
        {id: "del_1", status: "success"},
        {id: "del_2", status: "failed"}
      ]

      allow(described_class).to receive(:execute_request).with(
        :GET,
        "webhooks/webhook_123/deliveries",
        {},
        {}
      ).and_return({data: deliveries_data})

      result = webhook.deliveries
      expect(result).to eq(deliveries_data)
    end

    it "passes parameters" do
      allow(described_class).to receive(:execute_request).with(
        :GET,
        "webhooks/webhook_123/deliveries",
        {limit: 10, offset: 5},
        {}
      ).and_return({data: []})

      webhook.deliveries({limit: 10, offset: 5})
    end

    it "raises error for unpersisted webhook" do
      unpersisted = described_class.new({})
      expect { unpersisted.deliveries }.to raise_error(
        Attio::InvalidRequestError,
        "Cannot get deliveries for a webhook without an ID"
      )
    end

    it "handles empty response" do
      allow(described_class).to receive(:execute_request).and_return({})
      expect(webhook.deliveries).to eq([])
    end
  end

  describe "#save" do
    it "updates the webhook when changed" do
      webhook = described_class.new(webhook_attributes)
      webhook.target_url = "https://newurl.com/hook"

      expect(described_class).to receive(:update).with(
        "webhook_123",
        {target_url: "https://newurl.com/hook"}
      )

      webhook.save
    end

    it "returns self if nothing changed" do
      webhook = described_class.new(webhook_attributes)
      expect(described_class).not_to receive(:update)
      expect(webhook.save).to eq(webhook)
    end

    it "raises error for unpersisted webhook" do
      unpersisted = described_class.new({})
      expect { unpersisted.save }.to raise_error(
        Attio::InvalidRequestError,
        "Cannot save a webhook without an ID"
      )
    end

    it "handles nested webhook_id" do
      webhook = described_class.new(id: {"webhook_id" => "webhook_nested"})
      webhook.target_url = "https://changed.com/hook"

      expect(described_class).to receive(:update).with(
        "webhook_nested",
        {target_url: "https://changed.com/hook"}
      )

      webhook.save
    end
  end

  describe "#destroy" do
    it "deletes the webhook and freezes the object" do
      webhook = described_class.new(webhook_attributes)

      expect(described_class).to receive(:delete).with("webhook_123")

      result = webhook.destroy
      expect(result).to be true
      expect(webhook).to be_frozen
    end

    it "raises error for unpersisted webhook" do
      unpersisted = described_class.new({})
      expect { unpersisted.destroy }.to raise_error(
        Attio::InvalidRequestError,
        "Cannot destroy a webhook without an ID"
      )
    end

    it "handles nested webhook_id" do
      webhook = described_class.new(id: {"webhook_id" => "webhook_nested"})

      expect(described_class).to receive(:delete).with("webhook_nested")

      webhook.destroy
    end
  end

  describe "#to_h" do
    it "includes all webhook fields" do
      webhook = described_class.new(webhook_attributes)
      hash = webhook.to_h

      expect(hash).to include(
        target_url: "https://example.com/webhook",
        secret: "webhook_secret_123",
        last_event_at: "2023-01-15T10:30:00Z",
        created_by_actor: {type: "user", id: "usr_123"}
      )
    end

    it "compacts nil values" do
      webhook = described_class.new({})
      hash = webhook.to_h

      expect(hash).not_to have_key(:last_event_at)
      expect(hash).not_to have_key(:secret)
    end
  end

  describe ".create" do
    it "creates a webhook with valid parameters" do
      params = {
        target_url: "https://example.com/webhook",
        subscriptions: ["record.created"]
      }

      allow(described_class).to receive(:execute_request).with(
        :POST,
        "webhooks",
        {
          data: {
            target_url: "https://example.com/webhook",
            subscriptions: [
              {
                "event_type" => "record.created",
                "filter" => {"$and" => []}
              }
            ]
          }
        },
        {}
      ).and_return({"data" => webhook_attributes})

      result = described_class.create(**params)
      expect(result).to be_a(described_class)
    end

    it "accepts url parameter as alias for target_url" do
      params = {
        url: "https://example.com/webhook",
        subscriptions: ["record.created"]
      }

      expect(described_class).to receive(:execute_request) do |_, _, payload, _|
        expect(payload[:data][:target_url]).to eq("https://example.com/webhook")
        {"data" => webhook_attributes}
      end

      described_class.create(**params)
    end

    it "handles complex subscriptions with filters" do
      subscriptions = [
        {
          "event_type" => "record.created",
          "filter" => {"object_id" => "obj_123"}
        }
      ]

      expect(described_class).to receive(:execute_request) do |_, _, payload, _|
        expect(payload[:data][:subscriptions]).to eq(subscriptions)
        {"data" => webhook_attributes}
      end

      described_class.create(target_url: "https://example.com/webhook", subscriptions: subscriptions)
    end

    it "adds default filter to string event types" do
      expect(described_class).to receive(:execute_request) do |_, _, payload, _|
        expect(payload[:data][:subscriptions]).to eq([
          {"event_type" => "record.created", "filter" => {"$and" => []}}
        ])
        {"data" => webhook_attributes}
      end

      described_class.create(target_url: "https://example.com/webhook", subscriptions: ["record.created"])
    end

    it "validates target_url is required" do
      expect {
        described_class.create(subscriptions: ["record.created"])
      }.to raise_error(Attio::BadRequestError, "target_url or url is required")
    end

    it "validates target_url is HTTPS" do
      expect {
        described_class.create(target_url: "http://example.com/webhook", subscriptions: ["record.created"])
      }.to raise_error(Attio::BadRequestError, "Webhook target_url must use HTTPS")
    end

    it "validates target_url is valid URL" do
      expect {
        described_class.create(target_url: "not a url", subscriptions: ["record.created"])
      }.to raise_error(Attio::BadRequestError, "Invalid webhook target_url")
    end

    it "validates subscriptions are required" do
      expect {
        described_class.create(target_url: "https://example.com/webhook")
      }.to raise_error(ArgumentError, "subscriptions are required")
    end

    it "validates subscriptions must be array" do
      expect {
        described_class.create(target_url: "https://example.com/webhook", subscriptions: "not_array")
      }.to raise_error(ArgumentError, "subscriptions must be an array")
    end

    it "validates each subscription has event_type" do
      expect {
        described_class.create(
          target_url: "https://example.com/webhook",
          subscriptions: [{"filter" => {}}]
        )
      }.to raise_error(ArgumentError, "Each subscription must have an event_type")
    end

    it "passes api_key option" do
      allow(described_class).to receive(:execute_request).with(
        anything,
        anything,
        anything,
        {api_key: "custom_key"}
      ).and_return({"data" => webhook_attributes})

      described_class.create(
        target_url: "https://example.com/webhook",
        subscriptions: ["record.created"],
        api_key: "custom_key"
      )
    end
  end

  describe ".retrieve" do
    it "retrieves a webhook by ID" do
      allow(described_class).to receive(:execute_request).with(
        :GET,
        "webhooks/webhook_123",
        {},
        {}
      ).and_return({"data" => webhook_attributes})

      result = described_class.retrieve("webhook_123")
      expect(result).to be_a(described_class)
    end

    it "handles nested webhook_id" do
      allow(described_class).to receive(:execute_request).with(
        :GET,
        "webhooks/webhook_nested",
        {},
        {}
      ).and_return({"data" => webhook_attributes})

      result = described_class.retrieve({"webhook_id" => "webhook_nested"})
      expect(result).to be_a(described_class)
    end
  end

  describe ".delete" do
    it "deletes a webhook by ID" do
      allow(described_class).to receive(:execute_request).with(
        :DELETE,
        "webhooks/webhook_123",
        {},
        {}
      )

      result = described_class.delete("webhook_123")
      expect(result).to be true
    end

    it "handles nested webhook_id" do
      allow(described_class).to receive(:execute_request).with(
        :DELETE,
        "webhooks/webhook_nested",
        {},
        {}
      )

      result = described_class.delete({"webhook_id" => "webhook_nested"})
      expect(result).to be true
    end
  end

  describe "EVENTS constant" do
    it "includes all valid webhook event types" do
      expect(described_class::EVENTS).to include(
        "record.created", "record.updated", "record.deleted",
        "list_entry.created", "list_entry.deleted",
        "note.created", "note.deleted",
        "task.created", "task.updated", "task.deleted"
      )
      expect(described_class::EVENTS).to be_frozen
    end
  end

  describe "Constants" do
    it "exposes SignatureVerifier" do
      expect(described_class::SignatureVerifier).to eq(Attio::WebhookUtils::SignatureVerifier)
    end

    it "exposes Event" do
      expect(described_class::Event).to eq(Attio::WebhookUtils::Event)
    end
  end

  describe "API operations" do
    it "provides list operation" do
      expect(described_class).to respond_to(:list)
    end

    it "provides retrieve operation" do
      expect(described_class).to respond_to(:retrieve)
    end

    it "provides create operation" do
      expect(described_class).to respond_to(:create)
    end

    it "provides update operation" do
      expect(described_class).to respond_to(:update)
    end

    it "provides delete operation" do
      expect(described_class).to respond_to(:delete)
    end
  end
end
