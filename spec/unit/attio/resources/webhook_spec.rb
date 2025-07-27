# frozen_string_literal: true

require "spec_helper"
require "webmock/rspec"

RSpec.describe Attio::Webhook do
  let(:webhook_data) do
    {
      "id" => {
        "workspace_id" => "a96c9c20-442b-43cd-a94b-3d4683051661",
        "webhook_id" => "e2bedb34-dfce-4b3e-afdb-20bbe3ebedd5"
      },
      "target_url" => "https://example.com/webhook",
      "subscriptions" => [
        {
          "event_type" => "record.created",
          "filter" => {
            "object" => {"$in" => ["people"]}
          }
        }
      ],
      "status" => "active",
      "secret" => "secret_123",
      "last_event_at" => "2025-07-22T15:07:00.895000000Z",
      "created_by_actor" => {
        "type" => "user",
        "id" => "user_123"
      }
    }
  end

  describe ".list" do
    it "lists webhooks" do
      stub_request(:get, "https://api.attio.com/v2/webhooks")
        .to_return(
          status: 200,
          body: {"data" => [webhook_data]}.to_json,
          headers: {"Content-Type" => "application/json"}
        )

      result = described_class.list
      expect(result).to be_a(Attio::APIResource::ListObject)
      expect(result.first).to be_a(described_class) if result.any?
    end
  end

  describe ".create" do
    it "creates a webhook with valid parameters" do
      create_response = webhook_data.dup

      stub_request(:post, "https://api.attio.com/v2/webhooks")
        .with(
          body: {
            "data" => {
              "target_url" => "https://example.com/webhook",
              "subscriptions" => [{"event_type" => "record.created"}]
            }
          }.to_json
        )
        .to_return(
          status: 200,
          body: {"data" => create_response}.to_json,
          headers: {"Content-Type" => "application/json"}
        )

      webhook = described_class.create({
        target_url: "https://example.com/webhook",
        subscriptions: [{event_type: "record.created"}]
      })

      expect(webhook).to be_a(described_class)
      expect(webhook.target_url).to eq("https://example.com/webhook")
      expect(webhook.status).to eq("active")
    end

    it "validates target_url is required" do
      expect {
        described_class.create({subscriptions: [{event_type: "record.created"}]})
      }.to raise_error(ArgumentError, "target_url is required")
    end

    it "validates target_url must use HTTPS" do
      expect {
        described_class.create({
          target_url: "http://example.com/webhook",
          subscriptions: [{event_type: "record.created"}]
        })
      }.to raise_error(ArgumentError, "Webhook target_url must use HTTPS")
    end

    it "validates invalid URL format" do
      expect {
        described_class.create({
          target_url: "not a url",
          subscriptions: [{event_type: "record.created"}]
        })
      }.to raise_error(ArgumentError, "Invalid webhook target_url")
    end

    it "validates subscriptions are required" do
      expect {
        described_class.create({target_url: "https://example.com/webhook"})
      }.to raise_error(ArgumentError, "subscriptions are required")
    end

    it "validates subscriptions must be an array" do
      expect {
        described_class.create({
          target_url: "https://example.com/webhook",
          subscriptions: "not an array"
        })
      }.to raise_error(ArgumentError, "subscriptions must be an array")
    end

    it "validates each subscription must have event_type" do
      expect {
        described_class.create({
          target_url: "https://example.com/webhook",
          subscriptions: [{filter: {}}]
        })
      }.to raise_error(ArgumentError, "Each subscription must have an event_type")
    end

    it "handles API error response" do
      error_response = {
        "error" => "Invalid request"
      }

      stub_request(:post, "https://api.attio.com/v2/webhooks")
        .to_return(
          status: 400,
          body: error_response.to_json,
          headers: {"Content-Type" => "application/json"}
        )

      expect {
        described_class.create({
          target_url: "https://example.com/webhook",
          subscriptions: [{event_type: "record.created"}]
        })
      }.to raise_error(Attio::BadRequestError)
    end
  end

  describe ".retrieve" do
    it "retrieves a specific webhook" do
      webhook_id = "e2bedb34-dfce-4b3e-afdb-20bbe3ebedd5"

      stub_request(:get, "https://api.attio.com/v2/webhooks/#{webhook_id}")
        .to_return(
          status: 200,
          body: {"data" => webhook_data}.to_json,
          headers: {"Content-Type" => "application/json"}
        )

      webhook = described_class.retrieve(webhook_id)
      expect(webhook).to be_a(described_class)
      expect(webhook.id["webhook_id"]).to eq(webhook_id)
    end
  end

  describe ".update" do
    it "updates a webhook" do
      webhook_id = "e2bedb34-dfce-4b3e-afdb-20bbe3ebedd5"
      updated_data = webhook_data.merge("status" => "paused")

      stub_request(:patch, "https://api.attio.com/v2/webhooks/#{webhook_id}")
        .with(
          body: {"data" => {"status" => "paused"}}.to_json
        )
        .to_return(
          status: 200,
          body: {"data" => updated_data}.to_json,
          headers: {"Content-Type" => "application/json"}
        )

      webhook = described_class.update(webhook_id, {status: "paused"})
      expect(webhook.status).to eq("paused")
    end
  end

  describe ".delete" do
    it "deletes a webhook" do
      webhook_id = "e2bedb34-dfce-4b3e-afdb-20bbe3ebedd5"

      stub_request(:delete, "https://api.attio.com/v2/webhooks/#{webhook_id}")
        .to_return(status: 204)

      result = described_class.delete(webhook_id)
      expect(result).to be true
    end
  end

  describe "instance methods" do
    let(:webhook) { described_class.new(webhook_data) }

    describe "#initialize" do
      it "sets read-only attributes" do
        expect(webhook.secret).to eq("secret_123")
        expect(webhook.last_event_at).to be_a(Time)
        expect(webhook.created_by_actor).to eq({"type" => "user", "id" => "user_123"})
      end

      it "handles missing timestamps" do
        data = webhook_data.dup
        data.delete("last_event_at")
        webhook = described_class.new(data)
        expect(webhook.last_event_at).to be_nil
      end
    end

    describe "#active?" do
      it "returns true when status is active" do
        expect(webhook.active?).to be true
      end

      it "returns false when status is not active" do
        webhook.status = "paused"
        expect(webhook.active?).to be false
      end
    end

    describe "#paused?" do
      it "returns true when status is paused" do
        webhook.status = "paused"
        expect(webhook.paused?).to be true
      end

      it "returns false when status is not paused" do
        expect(webhook.paused?).to be false
      end
    end

    describe "#pause" do
      it "pauses the webhook" do
        stub_request(:patch, "https://api.attio.com/v2/webhooks/e2bedb34-dfce-4b3e-afdb-20bbe3ebedd5")
          .with(
            body: {"data" => {"status" => "paused"}}.to_json
          )
          .to_return(
            status: 200,
            body: {"data" => webhook_data.merge("status" => "paused")}.to_json,
            headers: {"Content-Type" => "application/json"}
          )

        webhook.pause
        expect(webhook.status).to eq("paused")
      end
    end

    describe "#resume" do
      it "resumes the webhook" do
        webhook.status = "paused"

        stub_request(:patch, "https://api.attio.com/v2/webhooks/e2bedb34-dfce-4b3e-afdb-20bbe3ebedd5")
          .with(
            body: {"data" => {"status" => "active"}}.to_json
          )
          .to_return(
            status: 200,
            body: {"data" => webhook_data}.to_json,
            headers: {"Content-Type" => "application/json"}
          )

        webhook.resume
        expect(webhook.status).to eq("active")
      end
    end

    describe "#activate" do
      it "is an alias for resume" do
        expect(webhook.method(:activate)).to eq(webhook.method(:resume))
      end
    end

    describe "#test" do
      it "tests the webhook" do
        stub_request(:post, "https://api.attio.com/v2/webhooks/e2bedb34-dfce-4b3e-afdb-20bbe3ebedd5/test")
          .to_return(status: 200, body: {}.to_json)

        result = webhook.test
        expect(result).to be true
      end

      it "raises error when not persisted" do
        unpersisted_webhook = described_class.new({})
        expect { unpersisted_webhook.test }.to raise_error(
          Attio::InvalidRequestError,
          "Cannot test a webhook without an ID"
        )
      end
    end

    describe "#deliveries" do
      it "gets webhook deliveries" do
        deliveries_data = [
          {
            "id" => "delivery_123",
            "status" => "success",
            "attempted_at" => "2025-07-27T12:00:00Z"
          }
        ]

        stub_request(:get, "https://api.attio.com/v2/webhooks/e2bedb34-dfce-4b3e-afdb-20bbe3ebedd5/deliveries")
          .to_return(
            status: 200,
            body: {"data" => deliveries_data}.to_json,
            headers: {"Content-Type" => "application/json"}
          )

        deliveries = webhook.deliveries
        expect(deliveries).to be_an(Array)
        expect(deliveries.first["id"]).to eq("delivery_123")
      end

      it "passes parameters" do
        stub_request(:get, "https://api.attio.com/v2/webhooks/e2bedb34-dfce-4b3e-afdb-20bbe3ebedd5/deliveries?limit=10")
          .to_return(
            status: 200,
            body: {"data" => []}.to_json,
            headers: {"Content-Type" => "application/json"}
          )

        result = webhook.deliveries({limit: 10})
        expect(result).to be_an(Array)
      end

      it "raises error when not persisted" do
        unpersisted_webhook = described_class.new({})
        expect { unpersisted_webhook.deliveries }.to raise_error(
          Attio::InvalidRequestError,
          "Cannot get deliveries for a webhook without an ID"
        )
      end
    end

    describe "#save" do
      it "saves changes to the webhook" do
        webhook[:target_url] = "https://new-example.com/webhook"

        stub_request(:patch, "https://api.attio.com/v2/webhooks/e2bedb34-dfce-4b3e-afdb-20bbe3ebedd5")
          .with(
            body: {"data" => {"target_url" => "https://new-example.com/webhook"}}.to_json
          )
          .to_return(
            status: 200,
            body: {"data" => webhook_data.merge("target_url" => "https://new-example.com/webhook")}.to_json,
            headers: {"Content-Type" => "application/json"}
          )

        result = webhook.save
        expect(result).to eq(webhook)
      end

      it "does nothing when not changed" do
        expect(webhook.changed?).to be false
        expect(webhook.save).to eq(webhook)
      end

      it "raises error when not persisted" do
        unpersisted_webhook = described_class.new({})
        expect { unpersisted_webhook.save }.to raise_error(
          Attio::InvalidRequestError,
          "Cannot save a webhook without an ID"
        )
      end
    end

    describe "#destroy" do
      it "deletes the webhook" do
        stub_request(:delete, "https://api.attio.com/v2/webhooks/e2bedb34-dfce-4b3e-afdb-20bbe3ebedd5")
          .to_return(status: 204)

        result = webhook.destroy
        expect(result).to be true
      end

      it "raises error when not persisted" do
        unpersisted_webhook = described_class.new({})
        expect { unpersisted_webhook.destroy }.to raise_error(
          Attio::InvalidRequestError,
          "Cannot destroy a webhook without an ID"
        )
      end
    end

    describe "#resource_path" do
      it "returns the correct path" do
        expect(webhook.resource_path).to eq("webhooks/e2bedb34-dfce-4b3e-afdb-20bbe3ebedd5")
      end

      it "handles simple ID format" do
        webhook = described_class.new({"id" => "simple-id"})
        expect(webhook.resource_path).to eq("webhooks/simple-id")
      end

      it "raises error when not persisted" do
        unpersisted_webhook = described_class.new({})
        expect { unpersisted_webhook.resource_path }.to raise_error(
          Attio::InvalidRequestError,
          "Cannot generate path without an ID"
        )
      end
    end

    describe "#to_h" do
      it "includes all webhook attributes" do
        hash = webhook.to_h
        expect(hash).to include(
          :id,
          :target_url,
          :subscriptions,
          :status,
          :secret,
          :created_by_actor
        )
        expect(hash[:last_event_at]).to match(/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z/)
      end

      it "excludes nil values" do
        data = webhook_data.dup
        data.delete("last_event_at")
        webhook = described_class.new(data)

        hash = webhook.to_h
        expect(hash).not_to have_key(:last_event_at)
      end
    end
  end

  describe "EVENTS constant" do
    it "includes all supported event types" do
      expect(described_class::EVENTS).to include(
        "record.created",
        "record.updated",
        "record.deleted",
        "list_entry.created",
        "list_entry.deleted",
        "note.created",
        "note.deleted",
        "task.created",
        "task.updated",
        "task.deleted",
        "object.created",
        "object.updated",
        "attribute.created",
        "attribute.updated",
        "attribute.archived"
      )
    end

    it "is frozen" do
      expect(described_class::EVENTS).to be_frozen
    end
  end
end
