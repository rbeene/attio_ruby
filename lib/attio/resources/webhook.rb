# frozen_string_literal: true

require_relative "../api_resource"
require_relative "../util/webhook_signature"

module Attio
  class Webhook < APIResource
    api_operations :list, :retrieve, :create, :update, :delete

    def self.resource_path
      "webhooks"
    end

    # Override id_key to use webhook_id
    def self.id_key
      :webhook_id
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

    # Override save to handle nested ID and support creation
    def save(**opts)
      if persisted?
        save_update(**opts)
      else
        save_create(**opts)
      end
    end

    protected

    def save_update(**opts)
      return self unless changed?

      params = {
        data: changed_attributes
      }

      path = Util::PathBuilder.build_resource_path(self.class.resource_path, extract_id)
      response = self.class.execute_request(HTTPMethods::PATCH, path, params, opts)
      update_from(response["data"] || response[:data] || response)
      reset_changes!
      self
    end

    def save_create(**opts)
      # Webhook requires target_url and subscriptions at minimum
      unless self[:target_url] && self[:subscriptions]
        raise InvalidRequestError, "Cannot save a new webhook without 'target_url' and 'subscriptions' attributes"
      end

      # Prepare all attributes for creation
      create_params = {
        target_url: self[:target_url],
        subscriptions: self[:subscriptions],
        status: self[:status]
      }.compact

      created = self.class.create(**create_params, **opts)

      if created
        @id = created.id
        @created_at = created.created_at
        @secret = created.secret
        @last_event_at = created.last_event_at
        @created_by_actor = created.created_by_actor
        update_from(created.instance_variable_get(:@attributes))
        reset_changes!
        self
      else
        raise InvalidRequestError, "Failed to create webhook"
      end
    end

    public

    # Override destroy to handle nested ID
    def destroy(**)
      raise InvalidRequestError, "Cannot destroy a webhook without an ID" unless persisted?

      self.class.delete(extract_id, **)
    end

    # Check if webhook is active
    def active?
      status == ResourceStates::ACTIVE
    end

    # Check if webhook is paused
    def paused?
      status == ResourceStates::PAUSED
    end

    # Pause the webhook
    def pause(**)
      self.status = ResourceStates::PAUSED
      save(**)
    end

    # Resume the webhook
    def resume(**)
      self.status = ResourceStates::ACTIVE
      save(**)
    end
    alias_method :activate, :resume

    # Test the webhook with a sample payload
    def test(**opts)
      raise InvalidRequestError, "Cannot test a webhook without an ID" unless persisted?

      path = Util::PathBuilder.build_resource_path(self.class.resource_path, extract_id, "test")
      self.class.execute_request(HTTPMethods::POST, path, {}, opts)
      true
    end

    # Get recent deliveries for this webhook
    def deliveries(params = {}, **opts)
      raise InvalidRequestError, "Cannot get deliveries for a webhook without an ID" unless persisted?

      path = Util::PathBuilder.build_resource_path(self.class.resource_path, extract_id, "deliveries")
      response = self.class.execute_request(HTTPMethods::GET, path, params, opts)
      response["data"] || response[:data] || []
    end

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

    # Verify webhook signature
    def verify_signature(payload:, signature:, timestamp:, tolerance: Util::WebhookSignature::TOLERANCE_SECONDS)
      raise InvalidRequestError, "Webhook secret not available" unless secret

      Util::WebhookSignature.verify(
        payload: payload,
        signature: signature,
        timestamp: timestamp,
        secret: secret,
        tolerance: tolerance
      )
    end

    # Verify webhook signature (raises exception on failure)
    def verify_signature!(payload:, signature:, timestamp:, tolerance: Util::WebhookSignature::TOLERANCE_SECONDS)
      raise InvalidRequestError, "Webhook secret not available" unless secret

      Util::WebhookSignature.verify!(
        payload: payload,
        signature: signature,
        timestamp: timestamp,
        secret: secret,
        tolerance: tolerance
      )
    end

    # Create a webhook handler for this webhook
    def create_handler
      raise InvalidRequestError, "Webhook secret not available" unless secret

      Util::WebhookSignature::Handler.new(secret)
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
        # If params already has data key, use it as is
        if params.key?(:data)
          params
        else
          {
            data: params
          }
        end
      end

      # Verify a webhook request
      # @param request [Hash, Rack::Request, ActionDispatch::Request] The incoming webhook request
      # @param secret [String] The webhook secret (if not using instance method)
      # @param tolerance [Integer] Time tolerance in seconds (default 300)
      # @return [Boolean] True if signature is valid
      # @example Verify a webhook from a Rack request
      #   if Attio::Webhook.verify_request(request, secret: webhook_secret)
      #     # Process webhook
      #   end
      def verify_request(request, secret:, tolerance: Util::WebhookSignature::TOLERANCE_SECONDS)
        handler = Util::WebhookSignature::Handler.new(secret)
        handler.verify_request(request)
        true
      rescue Util::WebhookSignature::SignatureVerificationError
        false
      end

      # Parse and verify a webhook request
      # @param request [Hash, Rack::Request, ActionDispatch::Request] The incoming webhook request
      # @param secret [String] The webhook secret
      # @return [Hash] The parsed webhook payload
      # @raise [SignatureVerificationError] If signature is invalid
      # @example Parse and verify a webhook
      #   payload = Attio::Webhook.parse_and_verify(request, secret: webhook_secret)
      #   event_type = payload[:event_type]
      def parse_and_verify(request, secret:)
        handler = Util::WebhookSignature::Handler.new(secret)
        handler.parse_and_verify(request)
      end

      # Create a webhook handler
      # @param secret [String] The webhook secret
      # @return [Util::WebhookSignature::Handler] A configured webhook handler
      # @example Create a handler for processing multiple webhooks
      #   handler = Attio::Webhook.create_handler(secret: webhook_secret)
      #   payload = handler.parse_and_verify(request)
      def create_handler(secret:)
        Util::WebhookSignature::Handler.new(secret)
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
