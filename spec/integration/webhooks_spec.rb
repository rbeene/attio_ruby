# frozen_string_literal: true

require "spec_helper"
require "webmock/rspec"

RSpec.describe "Webhook Integration", :integration do
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
          name: webhook_name,
          url: webhook_url,
          subscriptions: %w[record.created record.updated]
        }
      end

      it "returns a webhook instance" do
        VCR.use_cassette("webhooks/create") do
          webhook = Attio::Webhook.create(**webhook_params)
          expect(webhook).to be_a(Attio::Webhook)
        end
      end

      it "sets the webhook name" do
        VCR.use_cassette("webhooks/create") do
          webhook = Attio::Webhook.create(**webhook_params)
          expect(webhook.name).to eq(webhook_name)
        end
      end

      it "sets the webhook URL" do
        VCR.use_cassette("webhooks/create") do
          webhook = Attio::Webhook.create(**webhook_params)
          expect(webhook.url).to eq(webhook_url)
        end
      end

      it "sets the subscriptions" do
        VCR.use_cassette("webhooks/create") do
          webhook = Attio::Webhook.create(**webhook_params)
          expect(webhook.subscriptions).to include("record.created", "record.updated")
        end
      end

      it "creates an active webhook by default" do
        VCR.use_cassette("webhooks/create") do
          webhook = Attio::Webhook.create(**webhook_params)
          expect(webhook.active).to be true
        end
      end

      it "assigns a webhook ID" do
        VCR.use_cassette("webhooks/create") do
          webhook = Attio::Webhook.create(**webhook_params)
          expect(webhook.id).to be_present
        end
      end
    end

    it "retrieves a webhook" do
      VCR.use_cassette("webhooks/retrieve") do
        # Create webhook
        created = Attio::Webhook.create(
          name: webhook_name,
          url: webhook_url,
          subscriptions: %w[record.created]
        )

        # Retrieve it
        webhook = Attio::Webhook.retrieve(created.id)

        expect(webhook.id).to eq(created.id)
        expect(webhook.name).to eq(webhook_name)
        expect(webhook.url).to eq(webhook_url)
      end
    end

    it "lists all webhooks" do
      VCR.use_cassette("webhooks/list") do
        # Create a webhook first
        Attio::Webhook.create(
          name: webhook_name,
          url: webhook_url,
          subscriptions: %w[record.created]
        )

        # List all
        webhooks = Attio::Webhook.list

        expect(webhooks).to be_a(Attio::APIOperations::List::ListObject)
        expect(webhooks.count).to be > 0

        webhook_names = webhooks.map(&:name)
        expect(webhook_names).to include(webhook_name)
      end
    end

    it "updates a webhook" do
      VCR.use_cassette("webhooks/update") do
        # Create webhook
        webhook = Attio::Webhook.create(
          name: webhook_name,
          url: webhook_url,
          subscriptions: %w[record.created]
        )

        # Update
        webhook.name = "Updated #{webhook_name}"
        webhook.subscriptions = %w[record.created record.updated record.deleted]
        webhook.active = false
        webhook.save

        # Verify
        updated = Attio::Webhook.retrieve(webhook.id)
        expect(updated.name).to eq("Updated #{webhook_name}")
        expect(updated.subscriptions).to include("record.deleted")
        expect(updated.active).to be false
      end
    end

    it "deletes a webhook" do
      VCR.use_cassette("webhooks/delete") do
        # Create webhook
        webhook = Attio::Webhook.create(
          name: webhook_name,
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
        }.to raise_error(Attio::Errors::NotFoundError)
      end
    end
  end

  describe "webhook subscriptions" do
    it "supports all event types" do
      VCR.use_cassette("webhooks/all_events") do
        all_events = %w[
          record.created
          record.updated
          record.deleted
          list_entry.created
          list_entry.deleted
          note.created
          task.created
          task.updated
          task.completed
        ]

        webhook = Attio::Webhook.create(
          name: "All Events Webhook",
          url: "https://example.com/all-events",
          subscriptions: all_events
        )

        expect(webhook.subscriptions).to match_array(all_events)
      end
    end

    it "validates subscription types" do
      VCR.use_cassette("webhooks/invalid_subscription") do
        expect {
          Attio::Webhook.create(
            name: "Invalid Subscription",
            url: "https://example.com/invalid",
            subscriptions: %w[invalid.event]
          )
        }.to raise_error(Attio::Errors::InvalidRequestError)
      end
    end
  end

  describe "webhook activation" do
    let(:webhook) do
      Attio::Webhook.create(
        name: "Activation Test",
        url: "https://example.com/activation",
        subscriptions: %w[record.created]
      )
    end

    before do
      VCR.use_cassette("webhooks/setup_activation") { webhook }
    end

    it "toggles webhook activation" do
      VCR.use_cassette("webhooks/toggle_active") do
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
        expect(event.changes).to be_present
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
      VCR.use_cassette("webhooks/invalid_url") do
        expect {
          Attio::Webhook.create(
            name: "Invalid URL",
            url: "not-a-valid-url",
            subscriptions: %w[record.created]
          )
        }.to raise_error(Attio::Errors::InvalidRequestError)
      end
    end

    it "handles duplicate webhook" do
      VCR.use_cassette("webhooks/duplicate") do
        # Create first webhook
        Attio::Webhook.create(
          name: "Duplicate Test",
          url: "https://example.com/duplicate",
          subscriptions: %w[record.created]
        )

        # Try to create duplicate (same URL and subscriptions)
        expect {
          Attio::Webhook.create(
            name: "Duplicate Test 2",
            url: "https://example.com/duplicate",
            subscriptions: %w[record.created]
          )
        }.to raise_error(Attio::Errors::InvalidRequestError)
      end
    end
  end
end
