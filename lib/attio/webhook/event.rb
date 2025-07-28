# frozen_string_literal: true

module Attio
  module WebhookUtils
    # Represents a webhook event payload
    class Event
      attr_reader :id, :type, :occurred_at, :data, :raw_data

      def initialize(payload)
        @raw_data = payload.is_a?(String) ? JSON.parse(payload) : payload
        @id = @raw_data["id"] || @raw_data[:id]
        @type = @raw_data["type"] || @raw_data[:type]
        @occurred_at = parse_timestamp(@raw_data["occurred_at"] || @raw_data[:occurred_at])
        @data = @raw_data["data"] || @raw_data[:data] || {}
      end

      # Get the object type from the event data
      def object_type
        @data["object"] || @data[:object]
      end

      # Get the record from the event data
      def record
        @data["record"] || @data[:record]
      end

      # Get the record ID
      def record_id
        record_data = record
        return nil unless record_data

        record_data["id"] || record_data[:id]
      end

      # Get the record data
      def record_data
        record || {}
      end

      # Get changes from updated events
      def changes
        @data["changes"] || @data[:changes]
      end

      # Add present? method to match Rails expectations
      def present?
        true # Events are always present if they exist
      end

      # Check if this is a record event
      def record_event?
        type&.start_with?("record.")
      end

      # Check if this is a created event
      def created_event?
        type&.end_with?(".created")
      end

      # Check if this is an updated event
      def updated_event?
        type&.end_with?(".updated")
      end

      # Check if this is a deleted event
      def deleted_event?
        type&.end_with?(".deleted")
      end

      # Check if this is a list entry event
      def list_entry_event?
        type&.start_with?("list_entry.")
      end

      # Check if this is a note event
      def note_event?
        type&.start_with?("note.")
      end

      # Check if this is a task event
      def task_event?
        type&.start_with?("task.")
      end

      # Convert to hash
      def to_h
        {
          id: id,
          type: type,
          occurred_at: occurred_at&.iso8601,
          object_type: object_type,
          record_id: record_id,
          record_data: record_data,
          changes: changes,
          data: data
        }.compact
      end

      # Convert event back to JSON
      def to_json(*args)
        @raw_data.to_json(*args)
      end

      private

      def parse_timestamp(timestamp_str)
        return nil unless timestamp_str
        Time.parse(timestamp_str)
      rescue ArgumentError
        nil
      end
    end
  end
end
