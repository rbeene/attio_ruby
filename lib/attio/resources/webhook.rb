# frozen_string_literal: true

require_relative "../api_resource"

module Attio
  class Webhook < APIResource
    api_operations :list, :retrieve, :create, :update, :delete

    def self.resource_path
      "webhooks"
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
    attr_attio :target_url, :subscriptions, :status

    # Read-only attributes
    attr_reader :secret, :last_event_at, :created_by_actor

    def initialize(attributes = {}, opts = {})
      super
      normalized_attrs = normalize_attributes(attributes)
      @secret = normalized_attrs[:secret]
      @last_event_at = parse_timestamp(normalized_attrs[:last_event_at])
      @created_by_actor = normalized_attrs[:created_by_actor]
    end

    def resource_path
      raise InvalidRequestError, "Cannot generate path without an ID" unless persisted?
      webhook_id = id.is_a?(Hash) ? id["webhook_id"] : id
      "#{self.class.resource_path}/#{webhook_id}"
    end

    # Override save to handle nested ID
    def save(**)
      raise InvalidRequestError, "Cannot save a webhook without an ID" unless persisted?
      return self unless changed?

      webhook_id = id.is_a?(Hash) ? id["webhook_id"] : id
      self.class.update(webhook_id, changed_attributes, **)
    end

    # Override destroy to handle nested ID
    def destroy(**)
      raise InvalidRequestError, "Cannot destroy a webhook without an ID" unless persisted?

      webhook_id = id.is_a?(Hash) ? id["webhook_id"] : id
      self.class.delete(webhook_id, **)
    end

    # Check if webhook is active
    def active?
      status == "active"
    end

    # Check if webhook is paused
    def paused?
      status == "paused"
    end

    # Pause the webhook
    def pause(**)
      self.status = "paused"
      save(**)
    end

    # Resume the webhook
    def resume(**)
      self.status = "active"
      save(**)
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
        validate_target_url!(params[:target_url])
        validate_subscriptions!(params[:subscriptions])

        {
          data: {
            target_url: params[:target_url],
            subscriptions: Array(params[:subscriptions])
          }
        }
      end

      # Override update params preparation
      def prepare_params_for_update(params)
        {
          data: params
        }
      end

      private

      def validate_target_url!(url)
        raise ArgumentError, "target_url is required" if url.nil? || url.empty?

        uri = URI.parse(url)
        unless uri.scheme == "https"
          raise ArgumentError, "Webhook target_url must use HTTPS"
        end
      rescue URI::InvalidURIError
        raise ArgumentError, "Invalid webhook target_url"
      end

      def validate_subscriptions!(subscriptions)
        raise ArgumentError, "subscriptions are required" if subscriptions.nil? || subscriptions.empty?
        raise ArgumentError, "subscriptions must be an array" unless subscriptions.is_a?(Array)

        subscriptions.each do |sub|
          event_type = sub[:event_type] || sub["event_type"]
          raise ArgumentError, "Each subscription must have an event_type" unless event_type
        end
      end
    end
  end
end
