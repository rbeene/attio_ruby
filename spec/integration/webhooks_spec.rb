# frozen_string_literal: true

require "spec_helper"
require "webmock/rspec"

RSpec.describe "Webhook Integration", :integration, :webhook do
  before do
    Attio.configure do |config|
      config.api_key = ENV["ATTIO_API_KEY"]
    end
  end

  describe "webhook management" do
    let(:webhook_url) { "https://example.com/webhooks/attio" }
    let(:webhook_name) { "Test Webhook #{SecureRandom.hex(4)}" }

    describe "creating a webhook" do
      let(:webhook_params) do
        {
          url: webhook_url,
          subscriptions: %w[record.created record.updated]
        }
      end

      it "returns a webhook instance" do
        webhook = Attio::Webhook.create(**webhook_params)
        expect(webhook).to be_a(Attio::Webhook)
      end

      it "sets the webhook name", skip: "API does not return name field" do
        webhook = Attio::Webhook.create(**webhook_params)
        expect(webhook.name).to eq(webhook_name)
      end

      it "sets the webhook URL" do
        webhook = Attio::Webhook.create(**webhook_params)
        expect(webhook.url).to eq(webhook_url)
      end

      it "sets the subscriptions" do
        webhook = Attio::Webhook.create(**webhook_params)
        event_types = webhook.subscriptions.map { |s| s[:event_type] || s["event_type"] }
        expect(event_types).to include("record.created", "record.updated")
      end

      it "creates an active webhook by default" do
        webhook = Attio::Webhook.create(**webhook_params)
        expect(webhook.active).to be true
      end

      it "assigns a webhook ID" do
        webhook = Attio::Webhook.create(**webhook_params)
        expect(webhook.id).to be_truthy
      end
    end

    it "retrieves a webhook" do
      # Create webhook
      created = Attio::Webhook.create(
        url: webhook_url,
        subscriptions: %w[record.created]
      )

      # Retrieve it
      webhook = Attio::Webhook.retrieve(created.id)

      expect(webhook.id).to eq(created.id)
      expect(webhook.url).to eq(webhook_url)
    end

    it "lists all webhooks" do
      # Create a webhook first
      Attio::Webhook.create(
        url: webhook_url,
        subscriptions: %w[record.created]
      )

      # List all
      webhooks = Attio::Webhook.list

      expect(webhooks).to be_a(Attio::APIResource::ListObject)
      expect(webhooks.count).to be > 0

      webhook_urls = webhooks.map(&:url)
      expect(webhook_urls).to include(webhook_url)
    end

    it "updates a webhook", skip: "API update mechanism unclear" do
      # Create webhook
      webhook = Attio::Webhook.create(
        url: webhook_url,
        subscriptions: %w[record.created]
      )

      # Update - the API mechanism for this is unclear
      webhook.subscriptions = %w[record.created record.updated record.deleted]
      webhook.active = false
      webhook.save

      # Verify
      updated = Attio::Webhook.retrieve(webhook.id)
      expect(updated.subscriptions.map { |s| s["event_type"] }).to include("record.deleted")
      expect(updated.active).to be false
    end

    it "deletes a webhook" do
      # Create webhook
      webhook = Attio::Webhook.create(
        url: webhook_url,
        subscriptions: %w[record.created]
      )

      # Delete
      result = webhook.destroy
      expect(result).to be true
      expect(webhook).to be_frozen

      # Verify deletion
      expect {
        Attio::Webhook.retrieve(webhook.id)
      }.to raise_error(Attio::NotFoundError)
    end
  end

  describe "webhook subscriptions" do
    it "supports basic event types" do
      all_events = %w[
        record.created
        record.updated
        record.deleted
      ]

      webhook = Attio::Webhook.create(
        url: "https://example.com/all-events",
        subscriptions: all_events
      )

      event_types = webhook.subscriptions.map { |s| s[:event_type] || s["event_type"] }
      expect(event_types).to match_array(all_events)
    end

    it "validates subscription types" do
      expect {
        Attio::Webhook.create(
          url: "https://example.com/invalid",
          subscriptions: %w[invalid.event]
        )
      }.to raise_error(Attio::BadRequestError)
    end
  end

  describe "webhook activation" do
    let(:webhook) do
      Attio::Webhook.create(
        url: "https://example.com/activation",
        subscriptions: %w[record.created]
      )
    end

    before do
      webhook
    end

    it "toggles webhook activation", skip: "Update mechanism unclear from API docs" do
      # Should start active
      expect(webhook.active).to be true

      # Deactivate
      webhook.active = false
      webhook.save

      updated = Attio::Webhook.retrieve(webhook.id)
      expect(updated.active).to be false

      # Reactivate
      updated.active = true
      updated.save

      final = Attio::Webhook.retrieve(webhook.id)
      expect(final.active).to be true
    end
  end

  describe "webhook signature verification" do
    let(:payload) { '{"type":"record.created","data":{"object":"people"}}' }
    let(:secret) { "webhook_secret_key" }
    let(:timestamp) { Time.now.to_i.to_s }

    it "verifies valid signature" do
      # Generate valid signature
      signed_payload = "#{timestamp}.#{payload}"
      expected_signature = OpenSSL::HMAC.hexdigest("SHA256", secret, signed_payload)
      signature_header = "t=#{timestamp} v1=#{expected_signature}"

      # Verify
      verifier = Attio::Webhook::SignatureVerifier.new(secret)
      expect(verifier.verify(payload, signature_header)).to be true
    end

    it "rejects invalid signature" do
      signature_header = "t=#{timestamp} v1=invalid_signature"

      verifier = Attio::Webhook::SignatureVerifier.new(secret)
      expect(verifier.verify(payload, signature_header)).to be false
    end

    it "rejects old timestamp" do
      old_timestamp = (Time.now.to_i - 400).to_s # 400 seconds ago
      signed_payload = "#{old_timestamp}.#{payload}"
      signature = OpenSSL::HMAC.hexdigest("SHA256", secret, signed_payload)
      signature_header = "t=#{old_timestamp} v1=#{signature}"

      verifier = Attio::Webhook::SignatureVerifier.new(secret)
      expect(verifier.verify(payload, signature_header)).to be false
    end
  end

  describe "webhook payload parsing" do
    it "parses record created event" do
      payload = {
        id: "evt_123",
        type: "record.created",
        occurred_at: "2024-01-01T00:00:00Z",
        data: {
          object: "people",
          record: {
            id: "person_123",
            name: "John Doe",
            email_addresses: ["john@example.com"]
          }
        }
      }

      event = Attio::Webhook::Event.new(payload)

      expect(event.id).to eq("evt_123")
      expect(event.type).to eq("record.created")
      expect(event.object_type).to eq("people")
      expect(event.record_id).to eq("person_123")
      expect(event.record_data[:name]).to eq("John Doe")
    end

    context "with record updated event" do
      let(:updated_payload) do
        {
          id: "evt_124",
          type: "record.updated",
          occurred_at: "2024-01-01T00:00:00Z",
          data: {
            object: "people",
            record: {
              id: "person_123",
              name: "Jane Doe",
              email_addresses: ["jane@example.com"]
            },
            changes: {
              name: {old: "John Doe", new: "Jane Doe"},
              email_addresses: {
                old: ["john@example.com"],
                new: ["jane@example.com"]
              }
            }
          }
        }
      end

      it "parses record updated event" do
        event = Attio::Webhook::Event.new(updated_payload)
        expect(event.changes).to be_truthy
      end
    end

    it "parses changes in updated event" do
      payload = {
        id: "evt_124",
        type: "record.updated",
        occurred_at: "2024-01-01T00:00:00Z",
        data: {
          object: "people",
          record: {id: "person_123"},
          changes: {
            name: {old: "John Doe", new: "Jane Doe"}
          }
        }
      }

      event = Attio::Webhook::Event.new(payload)

      expect(event.changes[:name][:old]).to eq("John Doe")
      expect(event.changes[:name][:new]).to eq("Jane Doe")
    end
  end

  describe "error handling" do
    it "handles invalid webhook URL" do
      expect {
        Attio::Webhook.create(
          url: "not-a-valid-url",
          subscriptions: %w[record.created]
        )
      }.to raise_error(Attio::BadRequestError)
    end

    it "handles duplicate webhook", skip: "API allows duplicate webhooks" do
      # Create first webhook
      Attio::Webhook.create(
        url: "https://example.com/duplicate",
        subscriptions: %w[record.created]
      )

      # Try to create duplicate (same URL and subscriptions)
      expect {
        Attio::Webhook.create(
          url: "https://example.com/duplicate",
          subscriptions: %w[record.created]
        )
      }.to raise_error(Attio::BadRequestError)
    end
  end
end
