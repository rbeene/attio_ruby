# frozen_string_literal: true

require_relative "../api_resource"

module Attio
  # Represents an Attio Object (data model)
  #
  # Objects define the structure of data in your workspace. They contain
  # attributes that define what data can be stored on records.
  #
  # @example List all objects in the workspace
  #   objects = Attio::Object.list
  #   objects.each { |obj| puts "#{obj.plural_noun} (#{obj.api_slug})" }
  #
  # @example Get the people object
  #   people = Attio::Object.people
  #   # or
  #   people = Attio::Object.retrieve("people")
  #
  # @example Create records for an object
  #   people = Attio::Object.people
  #   person = people.create_record(
  #     name: "John Doe",
  #     email_addresses: "john@example.com"
  #   )
  class Object < APIResource
    api_operations :list, :retrieve, :create, :update, :delete

    def self.resource_path
      "objects"
    end

    # Override id_key to use object_id
    def self.id_key
      :object_id
    end

    # Define known attributes
    attr_reader :api_slug, :singular_noun, :plural_noun, :created_by_actor

    def initialize(attributes = {}, opts = {})
      super
      normalized_attrs = normalize_attributes(attributes)
      @api_slug = normalized_attrs[:api_slug]
      @singular_noun = normalized_attrs[:singular_noun]
      @plural_noun = normalized_attrs[:plural_noun]
      @created_by_actor = normalized_attrs[:created_by_actor]
    end

    # Get all attributes for this object
    # @param opts [Hash] Additional options
    # @return [ListObject] List of attributes
    # @example Get all attributes for the people object
    #   people = Attio::Object.people
    #   attributes = people.attributes
    #   attributes.each { |attr| puts "#{attr.name} (#{attr.type})" }
    def attributes(**opts)
      Attribute.list(object: api_slug || id, **opts)
    end

    # Create a new attribute for this object
    # @param params [Hash] Attribute parameters
    # @param opts [Hash] Additional options
    # @return [Attribute] The created attribute
    # @example Add a custom field to people
    #   people = Attio::Object.people
    #   attribute = people.create_attribute(
    #     name: "Customer ID",
    #     type: "text",
    #     is_required: false
    #   )
    def create_attribute(**params)
      # Extract opts from params if any
      opts = params.slice(:client, :api_key)
      attribute_params = params.except(:client, :api_key)

      Attribute.create(object: api_slug || id, **attribute_params, **opts)
    end

    # Get records for this object
    # @param params [Hash] Query parameters (filter, sort, limit, etc.)
    # @param opts [Hash] Additional options
    # @return [ListObject] Paginated list of records
    # @example Get all people records
    #   people = Attio::Object.people
    #   records = people.records(limit: 50)
    def records(**params)
      # Extract opts from params if any
      opts = params.slice(:client, :api_key)
      query_params = params.except(:client, :api_key)

      Record.list(object: api_slug || id, **query_params, **opts)
    end

    # Create a record for this object
    # @param values [Hash] The attribute values for the record
    # @param opts [Hash] Additional options
    # @return [Record] The created record
    # @example Create a new person
    #   people = Attio::Object.people
    #   person = people.create_record(
    #     name: "Jane Smith",
    #     email_addresses: "jane@example.com"
    #   )
    def create_record(values:, **opts)
      Record.create(object: api_slug || id, values: values, **opts)
    end

    # Find an object by its API slug
    # @param slug [String] The API slug of the object
    # @param opts [Hash] Additional options
    # @return [Object] The found object
    # @example Find a custom object
    #   deals = Attio::Object.find_by_slug("deals")
    def self.find_by_slug(slug, **opts)
      retrieve(slug, **opts)
    rescue NotFoundError
      list(**opts).find { |obj| obj.api_slug == slug }
    end

    # Get the standard people object
    # @param opts [Hash] Additional options
    # @return [Object] The people object
    # @example
    #   people = Attio::Object.people
    def self.people(**opts)
      find_by_slug("people", **opts)
    end

    # Get the standard companies object
    # @param opts [Hash] Additional options
    # @return [Object] The companies object
    # @example
    #   companies = Attio::Object.companies
    def self.companies(**opts)
      find_by_slug("companies", **opts)
    end
  end
end
