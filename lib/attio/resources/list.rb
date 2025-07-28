# frozen_string_literal: true

require "ostruct"
require_relative "../api_resource"

module Attio
  # Represents a list in Attio for organizing records
  class List < APIResource
    api_operations :list, :retrieve, :create, :update

    # API endpoint path for lists
    # @return [String] The API path
    def self.resource_path
      "lists"
    end

    # Define known attributes with proper accessors
    attr_attio :name, :workspace_access

    # Read-only attributes
    attr_reader :api_slug, :attio_object_id, :object_api_slug,
      :created_by_actor, :workspace_id, :parent_object, :filters

    # Get the parent object as a string
    def object
      # parent_object is returned as an array from the API
      return nil unless @parent_object
      @parent_object.is_a?(Array) ? @parent_object.first : @parent_object
    end

    def initialize(attributes = {}, opts = {})
      super

      # Now we can safely use symbol keys only since parent normalized them
      normalized_attrs = normalize_attributes(attributes)
      @api_slug = normalized_attrs[:api_slug]
      @name = normalized_attrs[:name]
      @attio_object_id = normalized_attrs[:object_id]
      @object_api_slug = normalized_attrs[:object_api_slug]
      @created_by_actor = normalized_attrs[:created_by_actor]
      @workspace_id = normalized_attrs[:workspace_id]
      @workspace_access = normalized_attrs[:workspace_access]
      @parent_object = normalized_attrs[:parent_object] || normalized_attrs[:object]
      @filters = normalized_attrs[:filters]
    end

    def resource_path
      raise InvalidRequestError, "Cannot generate path without an ID" unless persisted?
      list_id = id.is_a?(Hash) ? id["list_id"] : id
      "#{self.class.resource_path}/#{list_id}"
    end

    # Override the default id extraction for API paths
    def id_for_path
      return nil unless persisted?
      id.is_a?(Hash) ? id["list_id"] : id
    end

    # Override save to handle nested ID
    def save(**)
      raise InvalidRequestError, "Cannot save a list without an ID" unless persisted?
      return self unless changed?

      list_id = id.is_a?(Hash) ? id["list_id"] : id
      self.class.update(list_id, changed_attributes, **)
    end

    # Lists cannot be deleted via API
    def destroy(**opts)
      raise NotImplementedError, "Lists cannot be deleted via the Attio API"
    end

    # Get all entries in this list
    def entries(params = {}, **opts)
      list_id = id.is_a?(Hash) ? id["list_id"] : id
      client = Attio.client(api_key: opts[:api_key])
      # Use POST query endpoint to get entries
      response = client.post("lists/#{list_id}/entries/query", params)
      response["data"] || []
    end

    # Add a record to this list
    def add_record(record_id, **opts)
      list_id = id.is_a?(Hash) ? id["list_id"] : id
      client = Attio.client(api_key: opts[:api_key])

      # The API expects parent_record_id, parent_object, and entry_values
      request_data = {
        data: {
          parent_record_id: record_id,
          parent_object: object, # Get the parent object from the list
          entry_values: {}
        }
      }

      response = client.post("lists/#{list_id}/entries", request_data)
      # Return the entry data
      response["data"] || response
    end

    # Remove a record from this list
    def remove_record(entry_id, **opts)
      list_id = id.is_a?(Hash) ? id["list_id"] : id
      client = Attio.client(api_key: opts[:api_key])
      client.delete("lists/#{list_id}/entries/#{entry_id}")
    end

    # Check if a record is in this list
    def contains_record?(record_id, **)
      entries({record_id: record_id}, **).any?
    end

    # Get the count of entries
    def entry_count(**)
      # Just get the entries and count them
      entries(**).length
    end

    # Convert list to hash representation
    # @return [Hash] List data as a hash
    def to_h
      super.merge(
        api_slug: api_slug,
        name: name,
        object_id: attio_object_id,
        object_api_slug: object_api_slug,
        created_by_actor: created_by_actor,
        workspace_id: workspace_id,
        workspace_access: workspace_access
      ).compact
    end

    class << self
      # Override retrieve to handle complex IDs
      def retrieve(id, **opts)
        list_id = id.is_a?(Hash) ? id["list_id"] : id
        response = execute_request(:GET, "#{resource_path}/#{list_id}", {}, opts)
        new(response["data"] || response, opts)
      end

      # Override create to handle keyword arguments properly
      def create(**kwargs)
        # Extract options from kwargs
        opts = {}
        opts[:api_key] = kwargs.delete(:api_key) if kwargs.key?(:api_key)

        prepared_params = prepare_params_for_create(kwargs)
        response = execute_request(:POST, resource_path, prepared_params, opts)
        new(response["data"] || response, opts)
      end

      # Override create to handle special parameters
      def prepare_params_for_create(params)
        validate_object_identifier!(params[:object])

        # Generate api_slug from name if not provided
        api_slug = params[:api_slug] || params[:name].downcase.gsub(/[^a-z0-9]+/, "_")

        {
          data: {
            name: params[:name],
            parent_object: params[:object],
            api_slug: api_slug,
            workspace_access: params[:workspace_access] || "full-access",
            workspace_member_access: params[:workspace_member_access] || [],
            filters: params[:filters]
          }.compact
        }
      end

      # Override update to handle data wrapper
      def prepare_params_for_update(params)
        {
          data: params
        }
      end

      # Find list by API slug
      def find_by_slug(slug, **opts)
        list(**opts).find { |lst| lst.api_slug == slug } ||
          raise(NotFoundError, "List with slug '#{slug}' not found")
      end

      # Get lists for a specific object
      def for_object(object, params = {}, **)
        list(params.merge(object: object), **)
      end

      private

      def validate_object_identifier!(object)
        raise ArgumentError, "Object identifier is required" if object.nil? || object.to_s.empty?
      end
    end
  end
end
