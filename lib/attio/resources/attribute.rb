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

      response = self.class.send(:execute_request, :POST, "#{resource_path}/archive", {}, opts)
      response_data = response.is_a?(Hash) && response["data"] ? response["data"] : response
      # Update instance variables directly
      @is_archived = response_data[:is_archived] || response_data["is_archived"]
      @archived_at = parse_timestamp(response_data[:archived_at] || response_data["archived_at"])
      self
    end

    # Unarchive this attribute
    def unarchive(**opts)
      raise InvalidRequestError, "Cannot unarchive an attribute without an ID" unless persisted?

      response = self.class.send(:execute_request, :POST, "#{resource_path}/unarchive", {}, opts)
      response_data = response.is_a?(Hash) && response["data"] ? response["data"] : response
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

    def resource_path
      raise InvalidRequestError, "Cannot generate path without an ID" unless persisted?
      attribute_id = id.is_a?(Hash) ? id["attribute_id"] : id
      "#{self.class.resource_path}/#{attribute_id}"
    end

    # Override save to handle nested ID
    def save(**)
      raise InvalidRequestError, "Cannot save an attribute without an ID" unless persisted?
      return self unless changed?

      # Pass the full ID (including object context) to update method
      self.class.update(id, changed_attributes, **)
    end

    class << self
      # Override retrieve to handle object-scoped attributes
      def retrieve(id, **opts)
        # Extract simple ID if it's a nested hash
        attribute_id = id.is_a?(Hash) ? id["attribute_id"] : id
        validate_id!(attribute_id)

        # For attributes, we need the object context - check if it's in the nested ID
        if id.is_a?(Hash) && id["object_id"]
          object_id = id["object_id"]
          response = execute_request(:GET, "objects/#{object_id}/attributes/#{attribute_id}", {}, opts)
        else
          # Fall back to regular attributes endpoint
          response = execute_request(:GET, "#{resource_path}/#{attribute_id}", {}, opts)
        end

        new(response.is_a?(Hash) && response["data"] ? response["data"] : response, opts)
      end

      # Override update to handle object-scoped attributes
      def update(id, params = {}, **opts)
        # Extract simple ID if it's a nested hash
        attribute_id = id.is_a?(Hash) ? id["attribute_id"] : id
        validate_id!(attribute_id)

        # For attributes, we need the object context
        if id.is_a?(Hash) && id["object_id"]
          object_id = id["object_id"]
          prepared_params = prepare_params_for_update(params)
          response = execute_request(:PATCH, "objects/#{object_id}/attributes/#{attribute_id}", prepared_params, opts)
        else
          # Fall back to regular attributes endpoint
          prepared_params = prepare_params_for_update(params)
          response = execute_request(:PATCH, "#{resource_path}/#{attribute_id}", prepared_params, opts)
        end

        new(response.is_a?(Hash) && response["data"] ? response["data"] : response, opts)
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
      def list(params = {}, **opts)
        if params[:object]
          object = params.delete(:object)
          validate_object_identifier!(object)

          response = execute_request(:GET, "objects/#{object}/attributes", params, opts)
          APIResource::ListObject.new(response, self, params.merge(object: object), opts)
        else
          raise ArgumentError, "Attributes must be listed for a specific object. Use Attribute.for_object(object_slug) or pass object: parameter"
        end
      end

      # Override create to handle object-specific attributes
      def create(params = {}, **opts)
        object = params[:object]
        validate_object_identifier!(object)

        prepared_params = prepare_params_for_create(params)
        response = execute_request(:POST, "objects/#{object}/attributes", prepared_params, opts)
        new(response.is_a?(Hash) && response["data"] ? response["data"] : response, opts)
      end

      # List attributes for a specific object
      def for_object(object, **opts)
        list({object: object}.merge(opts))
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
