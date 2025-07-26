# frozen_string_literal: true

require_relative "base"
require_relative "../api_operations/list"
require_relative "../api_operations/retrieve"
require_relative "../api_operations/create"
require_relative "../api_operations/update"

module Attio
  class Attribute < Resources::Base
    include APIOperations::List
    include APIOperations::Retrieve
    include APIOperations::Create
    include APIOperations::Update

    # Attribute types
    TYPES = %w[
      text
      number
      checkbox
      date
      timestamp
      rating
      currency
      status
      select
      multiselect
      email
      phone
      url
      user
      record_reference
      location
    ].freeze

    # Type configurations
    TYPE_CONFIGS = {
      "text" => {supports_default: true, supports_required: true},
      "number" => {supports_default: true, supports_required: true, supports_unique: true},
      "checkbox" => {supports_default: true},
      "date" => {supports_default: true, supports_required: true},
      "timestamp" => {supports_default: true, supports_required: true},
      "rating" => {supports_default: true, max_value: 5},
      "currency" => {supports_default: true, supports_required: true},
      "status" => {requires_options: true},
      "select" => {requires_options: true, supports_default: true},
      "multiselect" => {requires_options: true},
      "email" => {supports_unique: true, supports_required: true},
      "phone" => {supports_required: true},
      "url" => {supports_required: true},
      "user" => {supports_required: true},
      "record_reference" => {requires_target_object: true, supports_required: true},
      "location" => {supports_required: true}
    }.freeze

    def self.resource_path
      "/attributes"
    end

    attr_reader :api_slug, :name, :description, :type, :is_required, :is_unique,
      :is_default_value_enabled, :default_value, :options,
      :attio_object_id, :object_api_slug, :parent_object_id,
      :created_by_actor, :is_archived, :archived_at

    def initialize(attributes = {}, opts = {})
      super

      # Now we can safely use symbol keys only since parent normalized them
      normalized_attrs = normalize_attributes(attributes)
      @api_slug = normalized_attrs[:api_slug]
      @name = normalized_attrs[:name]
      @description = normalized_attrs[:description]
      @type = normalized_attrs[:type]
      @is_required = normalized_attrs[:is_required] || false
      @is_unique = normalized_attrs[:is_unique] || false
      @is_default_value_enabled = normalized_attrs[:is_default_value_enabled] || false
      @default_value = normalized_attrs[:default_value]
      @options = normalized_attrs[:options]
      @attio_object_id = normalized_attrs[:object_id]
      @object_api_slug = normalized_attrs[:object_api_slug]
      @parent_object_id = normalized_attrs[:parent_object_id]
      @created_by_actor = normalized_attrs[:created_by_actor]
      @is_archived = normalized_attrs[:is_archived] || false
      @archived_at = parse_timestamp(normalized_attrs[:archived_at])
    end

    class << self
      # List attributes for an object
      def list(params = {}, object: nil, **opts)
        query_params = params.dup
        query_params[:object] = object if object

        request = RequestBuilder.build(
          method: :GET,
          path: resource_path,
          params: query_params,
          headers: opts[:headers] || {},
          api_key: opts[:api_key]
        )

        response = connection_manager.execute(request)
        parsed = ResponseParser.parse(response, request)

        APIOperations::List::ListObject.new(parsed, self, query_params, opts)
      end

      # Create an attribute
      def create(params = {}, object:, **opts)
        validate_object_identifier!(object)
        validate_type!(params[:type] || params["type"])
        validate_type_config!(params)

        attribute_params = prepare_attribute_params(params.merge(object: object))

        request = RequestBuilder.build(
          method: :POST,
          path: resource_path,
          params: attribute_params,
          headers: opts[:headers] || {},
          api_key: opts[:api_key]
        )

        response = connection_manager.execute(request)
        parsed = ResponseParser.parse(response, request)

        new(parsed, opts)
      end

      private

      def validate_object_identifier!(object)
        raise ArgumentError, "Object identifier is required" if object.nil? || object.to_s.empty?
      end

      def validate_type!(type)
        raise ArgumentError, "Attribute type is required" if type.nil? || type.to_s.empty?
        unless TYPES.include?(type.to_s)
          raise ArgumentError, "Invalid attribute type: #{type}. Valid types: #{TYPES.join(", ")}"
        end
      end

      def validate_type_config!(params)
        type = params[:type] || params["type"]
        config = TYPE_CONFIGS[type.to_s]
        return unless config

        # Check required options
        if config[:requires_options]
          options = params[:options] || params["options"]
          if options.nil? || (options.is_a?(Array) && options.empty?)
            raise ArgumentError, "Attribute type '#{type}' requires options"
          end
        end

        # Check required target object
        if config[:requires_target_object]
          target = params[:target_object] || params["target_object"]
          if target.nil? || target.to_s.empty?
            raise ArgumentError, "Attribute type '#{type}' requires target_object"
          end
        end

        # Validate unsupported features
        if params[:is_unique] && !config[:supports_unique]
          raise ArgumentError, "Attribute type '#{type}' does not support unique constraint"
        end

        if params[:is_required] && !config[:supports_required]
          raise ArgumentError, "Attribute type '#{type}' does not support required constraint"
        end

        if params[:is_default_value_enabled] && !config[:supports_default]
          raise ArgumentError, "Attribute type '#{type}' does not support default values"
        end
      end

      def prepare_attribute_params(params)
        {
          object: params[:object],
          name: params[:name],
          type: params[:type],
          description: params[:description],
          is_required: params[:is_required],
          is_unique: params[:is_unique],
          is_default_value_enabled: params[:is_default_value_enabled],
          default_value: params[:default_value],
          options: prepare_options(params[:options]),
          target_object: params[:target_object]
        }.compact
      end

      def prepare_options(options)
        return nil unless options

        case options
        when Array
          options.map do |opt|
            case opt
            when String
              {title: opt}
            when Hash
              opt
            else
              {title: opt.to_s}
            end
          end
        else
          options
        end
      end
    end

    # Instance methods

    def save(opts = {})
      if id.nil?
        raise Errors::InvalidRequestError, "Cannot update an attribute without an ID"
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

    def archive(opts = {})
      if id.nil?
        raise Errors::InvalidRequestError, "Cannot archive an attribute without an ID"
      end

      request = RequestBuilder.build(
        method: :POST,
        path: "#{resource_path}/#{id}/archive",
        headers: opts[:headers] || {},
        api_key: opts[:api_key] || @opts[:api_key]
      )

      response = connection_manager.execute(request)
      parsed = ResponseParser.parse(response, request)

      update_from(parsed)
      self
    end

    def unarchive(opts = {})
      if id.nil?
        raise Errors::InvalidRequestError, "Cannot unarchive an attribute without an ID"
      end

      request = RequestBuilder.build(
        method: :POST,
        path: "#{resource_path}/#{id}/unarchive",
        headers: opts[:headers] || {},
        api_key: opts[:api_key] || @opts[:api_key]
      )

      response = connection_manager.execute(request)
      parsed = ResponseParser.parse(response, request)

      update_from(parsed)
      self
    end

    def archived?
      @is_archived == true
    end

    def required?
      @is_required == true
    end

    def unique?
      @is_unique == true
    end

    def has_default?
      @is_default_value_enabled == true
    end

    def to_h
      super.merge(
        api_slug: api_slug,
        name: name,
        description: description,
        type: type,
        is_required: is_required,
        is_unique: is_unique,
        is_default_value_enabled: is_default_value_enabled,
        default_value: default_value,
        options: options,
        object_id: attio_object_id,
        object_api_slug: object_api_slug,
        parent_object_id: parent_object_id,
        created_by_actor: created_by_actor,
        is_archived: is_archived,
        archived_at: archived_at&.iso8601
      ).compact
    end

    private

    def prepare_update_params
      # Only certain fields can be updated
      updateable_fields = %i[
        name
        description
        is_required
        is_unique
        is_default_value_enabled
        default_value
        options
      ]

      params = {}
      updateable_fields.each do |field|
        if changed.include?(field.to_s)
          params[field] = send(field)
        end
      end

      params[:options] = self.class.send(:prepare_options, params[:options]) if params[:options]
      params
    end
  end
end
