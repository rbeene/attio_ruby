# frozen_string_literal: true

require_relative "../api_resource"
require_relative "../webhook/signature_verifier"
require_relative "../webhook/event"

module Attio
  # Represents a webhook configuration in Attio
  class Webhook < APIResource
    api_operations :list, :retrieve, :create, :update, :delete

    # API endpoint path for webhooks
    # @return [String] The API path
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
    attr_accessor :active

    # Alias url to target_url for convenience
    alias_method :url, :target_url
    alias_method :url=, :target_url=

    def initialize(attributes = {}, opts = {})
      super
      normalized_attrs = normalize_attributes(attributes)
      @secret = normalized_attrs[:secret]
      @last_event_at = parse_timestamp(normalized_attrs[:last_event_at])
      @created_by_actor = normalized_attrs[:created_by_actor]

      # Map status to active for convenience
      if status == "active"
        instance_variable_set(:@active, true)
      elsif status == "paused"
        instance_variable_set(:@active, false)
      end
    end

    def resource_path
      raise InvalidRequestError, "Cannot generate path without an ID" unless persisted?
      webhook_id = Util::IdExtractor.extract_for_resource(id, :webhook)
      "#{self.class.resource_path}/#{webhook_id}"
    end

    # Override save to handle nested ID
    def save(**)
      raise InvalidRequestError, "Cannot save a webhook without an ID" unless persisted?
      return self unless changed?

      webhook_id = Util::IdExtractor.extract_for_resource(id, :webhook)
      self.class.update(webhook_id, changed_attributes, **)
    end

    # Override destroy to handle nested ID
    def destroy(**opts)
      raise InvalidRequestError, "Cannot destroy a webhook without an ID" unless persisted?

      webhook_id = Util::IdExtractor.extract_for_resource(id, :webhook)
      self.class.delete(webhook_id, **opts)
      freeze
      true
    end

    # Check if webhook is active
    def active?
      active == true
    end

    # Check if webhook is paused
    def paused?
      !active?
    end

    # Pause the webhook
    def pause(**opts)
      self.active = false
      save(**opts)
    end

    # Resume the webhook
    def resume(**opts)
      self.active = true
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

    # Convert webhook to hash representation
    # @return [Hash] Webhook data as a hash
    def to_h
      super.merge(
        target_url: target_url,
        subscriptions: subscriptions,
        status: status,
        secret: secret,
        last_event_at: last_event_at&.iso8601,
        created_by_actor: created_by_actor
      ).compact
    end

    class << self
      # Override create to handle keyword arguments
      def create(**kwargs)
        opts = {}
        opts[:api_key] = kwargs.delete(:api_key) if kwargs.key?(:api_key)
        prepared_params = prepare_params_for_create(kwargs)
        response = execute_request(:POST, resource_path, prepared_params, opts)
        new(response["data"] || response, opts)
      end

      # Override retrieve to handle hash IDs
      def retrieve(id, **opts)
        webhook_id = Util::IdExtractor.extract_for_resource(id, :webhook)
        response = execute_request(:GET, "#{resource_path}/#{webhook_id}", {}, opts)
        new(response["data"] || response, opts)
      end

      # Override delete to handle hash IDs
      def delete(id, **opts)
        webhook_id = Util::IdExtractor.extract_for_resource(id, :webhook)
        execute_request(:DELETE, "#{resource_path}/#{webhook_id}", {}, opts)
        true
      end

      # Override create to handle validation
      def prepare_params_for_create(params)
        # Handle both url and target_url parameters for convenience
        target_url = params[:target_url] || params["target_url"] || params[:url] || params["url"]
        validate_target_url!(target_url)
        subscriptions = params[:subscriptions] || params["subscriptions"]
        validate_subscriptions!(subscriptions)

        {
          data: {
            target_url: target_url,
            subscriptions: Array(subscriptions).map do |sub|
              # Ensure each subscription has a filter
              sub = sub.is_a?(Hash) ? sub : {"event_type" => sub}
              sub["filter"] ||= {"$and" => []}  # Default empty filter
              sub
            end
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
        raise BadRequestError, "target_url or url is required" if url.nil? || url.empty?

        uri = URI.parse(url)
        unless uri.scheme == "https"
          raise BadRequestError, "Webhook target_url must use HTTPS"
        end
      rescue URI::InvalidURIError
        raise BadRequestError, "Invalid webhook target_url"
      end

      def validate_subscriptions!(subscriptions)
        raise ArgumentError, "subscriptions are required" if subscriptions.nil? || subscriptions.empty?
        raise ArgumentError, "subscriptions must be an array" unless subscriptions.is_a?(Array)

        subscriptions.each do |sub|
          event_type = if sub.is_a?(Hash)
            sub[:event_type] || sub["event_type"]
          else
            sub  # sub is a string representing the event type
          end
          raise ArgumentError, "Each subscription must have an event_type" unless event_type
        end
      end
    end

    # Constants to match expected API
    SignatureVerifier = WebhookUtils::SignatureVerifier
    Event = WebhookUtils::Event
  end
end
