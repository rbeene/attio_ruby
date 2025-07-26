# frozen_string_literal: true

require_relative "base"
require_relative "../api_operations/list"
require_relative "../api_operations/retrieve"
require_relative "../api_operations/create"
require_relative "../api_operations/update"
require_relative "../api_operations/delete"

module Attio
  class Webhook < Resources::Base
    include APIOperations::List
    include APIOperations::Retrieve
    include APIOperations::Create
    include APIOperations::Update
    include APIOperations::Delete

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

    attr_reader :url, :events, :state, :api_version, :secret,
      :last_event_at, :created_by_actor

    def initialize(attributes = {}, opts = {})
      super
      # Now we can safely use symbol keys only since parent normalized them
      normalized_attrs = normalize_attributes(attributes)
      @url = normalized_attrs[:url]
      @events = normalized_attrs[:events] || []
      @state = normalized_attrs[:state]
      @api_version = normalized_attrs[:api_version]
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
    def pause(opts = {})
      update_state("paused", opts)
    end

    # Resume the webhook
    def resume(opts = {})
      update_state("active", opts)
    end
    alias_method :activate, :resume

    # Test the webhook with a sample payload
    def test(opts = {})
      if id.nil?
        raise Errors::InvalidRequestError, "Cannot test a webhook without an ID"
      end

      request = RequestBuilder.build(
        method: :POST,
        path: "#{resource_path}/#{id}/test",
        headers: opts[:headers] || {},
        api_key: opts[:api_key] || @opts[:api_key]
      )

      response = connection_manager.execute(request)
      ResponseParser.parse(response, request)

      true
    end

    # Get recent deliveries for this webhook
    def deliveries(params = {}, opts = {})
      if id.nil?
        raise Errors::InvalidRequestError, "Cannot get deliveries for a webhook without an ID"
      end

      request = RequestBuilder.build(
        method: :GET,
        path: "#{resource_path}/#{id}/deliveries",
        params: params,
        headers: opts[:headers] || {},
        api_key: opts[:api_key] || @opts[:api_key]
      )

      response = connection_manager.execute(request)
      ResponseParser.parse(response, request)
    end

    def save(opts = {})
      if id.nil?
        raise Errors::InvalidRequestError, "Cannot update a webhook without an ID"
      end

      params = prepare_update_params

      request = RequestBuilder.build(
        method: :PATCH,
        path: resource_path,
        params: params,
        headers: opts[:headers] || {},
        api_key: opts[:api_key] || @opts[:api_key]
      )

      response = connection_manager.execute(request)
      parsed = ResponseParser.parse(response, request)

      update_from(parsed)
      reset_changes!
      self
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
      # Create a webhook
      def create(url:, events:, state: "active", opts: {})
        validate_url!(url)
        validate_events!(events)

        params = {
          url: url,
          events: Array(events),
          state: state
        }

        request = RequestBuilder.build(
          method: :POST,
          path: resource_path,
          params: params,
          headers: opts[:headers] || {},
          api_key: opts[:api_key]
        )

        response = connection_manager.execute(request)
        parsed = ResponseParser.parse(response, request)

        new(parsed, opts)
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

    private

    def update_state(new_state, opts = {})
      @state = new_state
      save(opts)
    end

    def prepare_update_params
      # Only certain fields can be updated
      updateable_fields = %i[url events state]

      params = {}
      updateable_fields.each do |field|
        value = send(field)
        params[field] = value unless value.nil?
      end

      # Validate if updating
      self.class.send(:validate_url!, params[:url]) if params[:url]
      self.class.send(:validate_events!, params[:events]) if params[:events]

      params
    end
  end
end
