# frozen_string_literal: true

require "spec_helper"

RSpec.describe Attio::WebhookUtils::Event do
  let(:event_payload) do
    {
      "id" => "evt_123",
      "type" => "record.created",
      "occurred_at" => "2023-01-15T10:30:00Z",
      "data" => {
        "object" => "people",
        "record" => {
          "id" => {"record_id" => "rec_123"},
          "values" => {
            "name" => [{"first_name" => "John", "last_name" => "Doe"}],
            "email_addresses" => ["john@example.com"]
          }
        }
      }
    }
  end

  describe "#initialize" do
    it "parses JSON string payload" do
      json_payload = event_payload.to_json
      event = described_class.new(json_payload)

      expect(event.id).to eq("evt_123")
      expect(event.type).to eq("record.created")
      expect(event.occurred_at).to be_a(Time)
      expect(event.data).to be_a(Hash)
    end

    it "accepts hash payload" do
      event = described_class.new(event_payload)

      expect(event.id).to eq("evt_123")
      expect(event.type).to eq("record.created")
      expect(event.occurred_at).to be_a(Time)
      expect(event.data).to eq(event_payload["data"])
    end

    it "handles symbol keys" do
      symbol_payload = {
        id: "evt_456",
        type: "record.updated",
        occurred_at: "2023-01-15T10:30:00Z",
        data: {object: "companies"}
      }

      event = described_class.new(symbol_payload)
      expect(event.id).to eq("evt_456")
      expect(event.type).to eq("record.updated")
      expect(event.object_type).to eq("companies")
    end

    it "handles missing data key" do
      minimal_payload = {
        "id" => "evt_789",
        "type" => "test.event"
      }

      event = described_class.new(minimal_payload)
      expect(event.data).to eq({})
    end

    it "handles nil occurred_at" do
      payload_without_timestamp = event_payload.dup
      payload_without_timestamp.delete("occurred_at")

      event = described_class.new(payload_without_timestamp)
      expect(event.occurred_at).to be_nil
    end

    it "handles invalid timestamp" do
      payload_with_invalid_timestamp = event_payload.dup
      payload_with_invalid_timestamp["occurred_at"] = "invalid-timestamp"

      event = described_class.new(payload_with_invalid_timestamp)
      expect(event.occurred_at).to be_nil
    end
  end

  describe "#object_type" do
    it "returns the object type from data" do
      event = described_class.new(event_payload)
      expect(event.object_type).to eq("people")
    end

    it "handles symbol keys" do
      event = described_class.new(data: {object: "companies"})
      expect(event.object_type).to eq("companies")
    end

    it "returns nil when not present" do
      event = described_class.new(id: "evt_123", type: "test")
      expect(event.object_type).to be_nil
    end
  end

  describe "#record" do
    it "returns the record from data" do
      event = described_class.new(event_payload)
      expect(event.record).to eq(event_payload["data"]["record"])
    end

    it "handles symbol keys" do
      event = described_class.new(data: {record: {id: "rec_123"}})
      expect(event.record).to eq({id: "rec_123"})
    end

    it "returns nil when not present" do
      event = described_class.new(data: {object: "people"})
      expect(event.record).to be_nil
    end
  end

  describe "#record_id" do
    it "extracts record ID from nested structure" do
      event = described_class.new(event_payload)
      expect(event.record_id).to eq({"record_id" => "rec_123"})
    end

    it "handles simple ID format" do
      simple_payload = {
        data: {
          record: {
            id: "rec_simple"
          }
        }
      }

      event = described_class.new(simple_payload)
      expect(event.record_id).to eq("rec_simple")
    end

    it "returns nil when record is missing" do
      event = described_class.new(data: {object: "people"})
      expect(event.record_id).to be_nil
    end

    it "returns nil when record has no ID" do
      event = described_class.new(data: {record: {values: {}}})
      expect(event.record_id).to be_nil
    end
  end

  describe "#record_data" do
    it "returns the record data" do
      event = described_class.new(event_payload)
      expect(event.record_data).to eq(event_payload["data"]["record"])
    end

    it "returns empty hash when record is missing" do
      event = described_class.new(data: {object: "people"})
      expect(event.record_data).to eq({})
    end
  end

  describe "#changes" do
    let(:update_payload) do
      {
        type: "record.updated",
        data: {
          record: {id: "rec_123"},
          changes: {
            name: {
              old: [{"first_name" => "John"}],
              new: [{"first_name" => "Jane"}]
            }
          }
        }
      }
    end

    it "returns changes for update events" do
      event = described_class.new(update_payload)
      expect(event.changes).to eq(update_payload[:data][:changes])
    end

    it "returns nil when no changes present" do
      event = described_class.new(event_payload)
      expect(event.changes).to be_nil
    end
  end

  describe "#present?" do
    it "always returns true" do
      event = described_class.new({})
      expect(event.present?).to be true
    end
  end

  describe "event type checking methods" do
    describe "#record_event?" do
      it "returns true for record events" do
        event = described_class.new(type: "record.created")
        expect(event.record_event?).to be true
      end

      it "returns false for non-record events" do
        event = described_class.new(type: "list_entry.created")
        expect(event.record_event?).to be false
      end

      it "handles nil type" do
        event = described_class.new({})
        # nil&.start_with? returns nil, not false
        expect(event.record_event?).to be_nil
      end
    end

    describe "#created_event?" do
      it "returns true for created events" do
        event = described_class.new(type: "record.created")
        expect(event.created_event?).to be true
      end

      it "returns false for non-created events" do
        event = described_class.new(type: "record.updated")
        expect(event.created_event?).to be false
      end
    end

    describe "#updated_event?" do
      it "returns true for updated events" do
        event = described_class.new(type: "record.updated")
        expect(event.updated_event?).to be true
      end

      it "returns false for non-updated events" do
        event = described_class.new(type: "record.created")
        expect(event.updated_event?).to be false
      end
    end

    describe "#deleted_event?" do
      it "returns true for deleted events" do
        event = described_class.new(type: "record.deleted")
        expect(event.deleted_event?).to be true
      end

      it "returns false for non-deleted events" do
        event = described_class.new(type: "record.created")
        expect(event.deleted_event?).to be false
      end
    end

    describe "#list_entry_event?" do
      it "returns true for list entry events" do
        event = described_class.new(type: "list_entry.created")
        expect(event.list_entry_event?).to be true
      end

      it "returns false for non-list entry events" do
        event = described_class.new(type: "record.created")
        expect(event.list_entry_event?).to be false
      end
    end

    describe "#note_event?" do
      it "returns true for note events" do
        event = described_class.new(type: "note.created")
        expect(event.note_event?).to be true
      end

      it "returns false for non-note events" do
        event = described_class.new(type: "record.created")
        expect(event.note_event?).to be false
      end
    end

    describe "#task_event?" do
      it "returns true for task events" do
        event = described_class.new(type: "task.created")
        expect(event.task_event?).to be true
      end

      it "returns false for non-task events" do
        event = described_class.new(type: "record.created")
        expect(event.task_event?).to be false
      end
    end
  end

  describe "#to_h" do
    it "converts event to hash with all fields" do
      event = described_class.new(event_payload)
      hash = event.to_h

      expect(hash).to include(
        id: "evt_123",
        type: "record.created",
        occurred_at: "2023-01-15T10:30:00Z",
        object_type: "people",
        record_id: {"record_id" => "rec_123"},
        data: event_payload["data"]
      )
    end

    it "includes changes for update events" do
      update_payload = event_payload.merge(
        "type" => "record.updated",
        "data" => event_payload["data"].merge(
          "changes" => {"name" => {"old" => "John", "new" => "Jane"}}
        )
      )

      event = described_class.new(update_payload)
      hash = event.to_h

      expect(hash[:changes]).to eq({"name" => {"old" => "John", "new" => "Jane"}})
    end

    it "compacts nil values" do
      minimal_event = described_class.new(id: "evt_123", type: "test")
      hash = minimal_event.to_h

      expect(hash).to have_key(:id)
      expect(hash).to have_key(:type)
      expect(hash).not_to have_key(:occurred_at)
      expect(hash).not_to have_key(:object_type)
      expect(hash).not_to have_key(:record_id)
      expect(hash).not_to have_key(:changes)
    end
  end

  describe "#to_json" do
    it "converts back to JSON string" do
      event = described_class.new(event_payload)
      json = event.to_json

      parsed = JSON.parse(json)
      expect(parsed["id"]).to eq("evt_123")
      expect(parsed["type"]).to eq("record.created")
    end

    it "preserves original payload structure" do
      event = described_class.new(event_payload)
      json = event.to_json

      expect(JSON.parse(json)).to eq(event_payload)
    end

    it "accepts JSON generation options" do
      event = described_class.new(id: "evt_123")
      # Just verify it accepts options without error
      expect { event.to_json(pretty: true) }.not_to raise_error
    end
  end

  describe "edge cases" do
    it "handles completely empty payload" do
      event = described_class.new({})

      expect(event.id).to be_nil
      expect(event.type).to be_nil
      expect(event.occurred_at).to be_nil
      expect(event.data).to eq({})
      expect { event.to_h }.not_to raise_error
    end

    it "handles nested record ID structures" do
      complex_payload = {
        data: {
          record: {
            id: {
              record_id: "rec_123",
              object_id: "obj_456"
            }
          }
        }
      }

      event = described_class.new(complex_payload)
      expect(event.record_id).to eq({record_id: "rec_123", object_id: "obj_456"})
    end

    it "handles malformed JSON gracefully" do
      expect {
        described_class.new("invalid json")
      }.to raise_error(JSON::ParserError)
    end
  end
end
