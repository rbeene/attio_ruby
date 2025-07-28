# frozen_string_literal: true

require_relative "../api_resource"

module Attio
  class Attribute < APIResource
    api_operations :list, :retrieve, :create, :update

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
      "attributes"
    end

    # Override id_key to use attribute_id
    def self.id_key
      :attribute_id
    end

    # Define known attributes with proper accessors
    attr_attio :name, :description, :is_required, :is_unique,
      :is_default_value_enabled, :default_value, :options

    # Read-only attributes
    attr_reader :api_slug, :type, :attio_object_id, :object_api_slug,
      :parent_object_id, :created_by_actor, :is_archived, :archived_at,
      :title

    def initialize(attributes = {}, opts = {})
      super
      normalized_attrs = normalize_attributes(attributes)
      @api_slug = normalized_attrs[:api_slug]
      @type = normalized_attrs[:type]
      @attio_object_id = normalized_attrs[:object_id]
      @object_api_slug = normalized_attrs[:object_api_slug]
      @parent_object_id = normalized_attrs[:parent_object_id]
      @created_by_actor = normalized_attrs[:created_by_actor]
      @is_archived = normalized_attrs[:is_archived] || false
      @archived_at = parse_timestamp(normalized_attrs[:archived_at])
      @title = normalized_attrs[:title]
    end

    # Archive this attribute
    def archive(**opts)
      raise InvalidRequestError, "Cannot archive an attribute without an ID" unless persisted?

      path = Util::PathBuilder.build_resource_path(self.class.resource_path, extract_id, "archive")
      response = self.class.execute_request(HTTPMethods::POST, path, {}, opts)
      response_data = (response.is_a?(Hash) && response["data"]) ? response["data"] : response
      # Update instance variables directly
      @is_archived = response_data[:is_archived] || response_data["is_archived"]
      @archived_at = parse_timestamp(response_data[:archived_at] || response_data["archived_at"])
      self
    end

    # Unarchive this attribute
    def unarchive(**opts)
      raise InvalidRequestError, "Cannot unarchive an attribute without an ID" unless persisted?

      path = Util::PathBuilder.build_resource_path(self.class.resource_path, extract_id, "unarchive")
      response = self.class.execute_request(HTTPMethods::POST, path, {}, opts)
      response_data = (response.is_a?(Hash) && response["data"]) ? response["data"] : response
      # Update instance variables directly
      @is_archived = response_data[:is_archived] || response_data["is_archived"]
      @archived_at = parse_timestamp(response_data[:archived_at] || response_data["archived_at"])
      self
    end

    def archived?
      @is_archived == true
    end

    def required?
      is_required == true
    end

    def unique?
      is_unique == true
    end

    def has_default?
      is_default_value_enabled == true
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

      # Pass the full ID (including object context) to update method
      updated = if id.is_a?(Hash) && id["object_id"]
        self.class.update(attribute_id: extract_id(:attribute_id), object: extract_id(:object_id), **changed_attributes, **opts)
      else
        self.class.update(attribute_id: extract_id, **changed_attributes, **opts)
      end

      update_from(updated.instance_variable_get(:@attributes)) if updated
      reset_changes!
      self
    end

    def save_create(**opts)
      # Attribute requires object, name, and type at minimum
      unless self[:object] && self[:name] && self[:type]
        raise InvalidRequestError, "Cannot save a new attribute without 'object', 'name', and 'type' attributes"
      end

      # Prepare all attributes for creation
      create_params = {
        object: self[:object],
        name: self[:name],
        type: self[:type],
        api_slug: self[:api_slug],
        description: self[:description],
        is_required: self[:is_required],
        is_unique: self[:is_unique],
        is_default_value_enabled: self[:is_default_value_enabled],
        default_value: self[:default_value],
        options: self[:options],
        target_object: self[:target_object],
        target_relation_type: self[:target_relation_type]
      }.compact

      created = self.class.create(**create_params, **opts)

      if created
        @id = created.id
        @created_at = created.created_at
        @api_slug = created.api_slug
        @type = created.type
        @attio_object_id = created.attio_object_id
        @object_api_slug = created.object_api_slug
        update_from(created.instance_variable_get(:@attributes))
        reset_changes!
        self
      else
        raise InvalidRequestError, "Failed to create attribute"
      end
    end

    public

    class << self
      # Override retrieve to handle object-scoped attributes
      def retrieve(attribute_id:, object: nil, **opts)
        # Handle both simple ID and nested hash for backwards compatibility
        if attribute_id.is_a?(Hash)
          actual_id = attribute_id["attribute_id"]
          object ||= attribute_id["object_id"]
        else
          actual_id = attribute_id
        end
        validate_id!(actual_id)

        # For attributes, we need the object context
        path = if object
          Util::PathBuilder.build_resource_path("objects", object, "attributes", actual_id)
        else
          # Fall back to regular attributes endpoint
          Util::PathBuilder.build_resource_path(resource_path, actual_id)
        end
        response = execute_request(HTTPMethods::GET, path, {}, opts)

        new((response.is_a?(Hash) && response["data"]) ? response["data"] : response, opts)
      end

      # Override update to handle object-scoped attributes
      def update(attribute_id:, object: nil, **params)
        # Separate opts from params
        opts = params.select { |k, _| k == :client || k == :api_key }
        update_params = params.except(:client, :api_key)

        # Handle both simple ID and nested hash for backwards compatibility
        if attribute_id.is_a?(Hash)
          actual_id = attribute_id["attribute_id"]
          object ||= attribute_id["object_id"]
        else
          actual_id = attribute_id
        end
        validate_id!(actual_id)

        # For attributes, we need the object context
        prepared_params = prepare_params_for_update(update_params)
        path = if object
          Util::PathBuilder.build_resource_path("objects", object, "attributes", actual_id)
        else
          # Fall back to regular attributes endpoint
          Util::PathBuilder.build_resource_path(resource_path, actual_id)
        end
        response = execute_request(HTTPMethods::PATCH, path, prepared_params, opts)

        new((response.is_a?(Hash) && response["data"]) ? response["data"] : response, opts)
      end

      # Override create to handle validation and object parameter
      def prepare_params_for_create(params)
        validate_type!(params[:type])
        validate_type_config!(params)

        # Generate api_slug from name if not provided
        api_slug = params[:api_slug] || params[:name].downcase.gsub(/[^a-z0-9]+/, "_")

        {
          data: {
            title: params[:name] || params[:title],
            api_slug: api_slug,
            type: params[:type],
            description: params[:description],
            is_required: params[:is_required] || false,
            is_unique: params[:is_unique] || false,
            is_multiselect: params[:is_multiselect] || false,
            default_value: params[:default_value],
            config: params[:config] || {}
          }.compact
        }
      end

      # Override update params preparation
      def prepare_params_for_update(params)
        # Only certain fields can be updated
        updateable_fields = %i[
          name
          title
          description
          is_required
          is_unique
          default_value
          options
        ]

        update_params = params.slice(*updateable_fields)
        update_params[:options] = prepare_options(update_params[:options]) if update_params[:options]

        # Wrap in data for API
        {
          data: update_params
        }
      end

      # Override list to handle object-specific attributes
      def list(object:, **opts)
        validate_object_identifier!(object)

        # Extract query parameters
        query_params = opts.except(:client, :api_key)
        request_opts = opts.slice(:client, :api_key)

        path = Util::PathBuilder.build_resource_path("objects", object, "attributes")
        response = execute_request(HTTPMethods::GET, path, query_params, request_opts)
        APIResource::ListObject.new(response, self, opts.merge(object: object), request_opts)
      end

      # Override create to handle object-specific attributes
      def create(object:, name:, type:, **params)
        validate_object_identifier!(object)

        # Separate opts from params
        opts = params.slice(:client, :api_key)
        create_params = params.except(:client, :api_key).merge(object: object, name: name, type: type)

        prepared_params = prepare_params_for_create(create_params)
        path = Util::PathBuilder.build_resource_path("objects", object, "attributes")
        response = execute_request(HTTPMethods::POST, path, prepared_params, opts)
        new((response.is_a?(Hash) && response["data"]) ? response["data"] : response, opts)
      end

      # List attributes for a specific object
      def for_object(object, **opts)
        list(object: object, **opts)
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
        type = params[:type]
        config = TYPE_CONFIGS[type.to_s]
        return unless config

        # Check required options
        if config[:requires_options]
          options = params[:options]
          if options.nil? || (options.is_a?(Array) && options.empty?)
            raise ArgumentError, "Attribute type '#{type}' requires options"
          end
        end

        # Check required target object
        if config[:requires_target_object]
          target = params[:target_object]
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
  end
end
