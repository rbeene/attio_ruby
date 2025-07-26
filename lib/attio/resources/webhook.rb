# frozen_string_literal: true

require_relative "../api_resource"

module Attio
  class Webhook < APIResource
    api_operations :list, :retrieve, :create, :update, :delete

    def self.resource_path
      "/webhooks"
    end

    # Event types
    EVENTS = %w[
      record.created
      record.updated
      record.deleted
      list_entry.created
      list_entry.deleted
      note.created
      note.deleted
      task.created
      task.updated
      task.deleted
      object.created
      object.updated
      attribute.created
      attribute.updated
      attribute.archived
    ].freeze

    # Define known attributes with proper accessors
    attr_attio :url, :events, :state, :api_version

    # Read-only attributes
    attr_reader :secret, :last_event_at, :created_by_actor

    def initialize(attributes = {}, opts = {})
      super
      normalized_attrs = normalize_attributes(attributes)
      @secret = normalized_attrs[:secret]
      @last_event_at = parse_timestamp(normalized_attrs[:last_event_at])
      @created_by_actor = normalized_attrs[:created_by_actor]
    end

    # Check if webhook is active
    def active?
      state == "active"
    end

    # Check if webhook is paused
    def paused?
      state == "paused"
    end

    # Pause the webhook
    def pause(**opts)
      self.state = "paused"
      save(**opts)
    end

    # Resume the webhook
    def resume(**opts)
      self.state = "active"
      save(**opts)
    end
    alias_method :activate, :resume

    # Test the webhook with a sample payload
    def test(**opts)
      raise InvalidRequestError, "Cannot test a webhook without an ID" unless persisted?

      self.class.send(:execute_request, :POST, "#{resource_path}/test", {}, opts)
      true
    end

    # Get recent deliveries for this webhook
    def deliveries(params = {}, **opts)
      raise InvalidRequestError, "Cannot get deliveries for a webhook without an ID" unless persisted?

      response = self.class.send(:execute_request, :GET, "#{resource_path}/deliveries", params, opts)
      response[:data] || []
    end

    def to_h
      super.merge(
        url: url,
        events: events,
        state: state,
        api_version: api_version,
        secret: secret,
        last_event_at: last_event_at&.iso8601,
        created_by_actor: created_by_actor
      ).compact
    end

    class << self
      # Override create to handle validation
      def prepare_params_for_create(params)
        validate_url!(params[:url])
        validate_events!(params[:events])

        {
          url: params[:url],
          events: Array(params[:events]),
          state: params[:state] || "active"
        }
      end

      # Override update params preparation
      def prepare_params_for_update(params)
        # Only certain fields can be updated
        updateable_fields = %i[url events state]
        update_params = params.slice(*updateable_fields)

        # Validate if updating
        validate_url!(update_params[:url]) if update_params[:url]
        validate_events!(update_params[:events]) if update_params[:events]

        update_params
      end

      private

      def validate_url!(url)
        raise ArgumentError, "URL is required" if url.nil? || url.empty?

        uri = URI.parse(url)
        unless uri.scheme == "https"
          raise ArgumentError, "Webhook URL must use HTTPS"
        end
      rescue URI::InvalidURIError
        raise ArgumentError, "Invalid webhook URL"
      end

      def validate_events!(events)
        events = Array(events)
        raise ArgumentError, "At least one event is required" if events.empty?

        invalid_events = events - EVENTS
        unless invalid_events.empty?
          raise ArgumentError, "Invalid events: #{invalid_events.join(", ")}. Valid events: #{EVENTS.join(", ")}"
        end
      end
    end
  end
end