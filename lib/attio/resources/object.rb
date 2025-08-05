# frozen_string_literal: true

require_relative "../api_resource"

module Attio
  # Represents an object type in Attio (e.g., People, Companies)
  class Object < APIResource
    api_operations :list, :retrieve, :create, :update, :delete

    # API endpoint path for objects
    # @return [String] The API path
    def self.resource_path
      "objects"
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
    def attributes(**)
      Attribute.list(parent_object: api_slug || id, **)
    end

    # Create a new attribute for this object
    def create_attribute(params = {}, **)
      Attribute.create(params.merge(parent_object: api_slug || id), **)
    end

    # Get records for this object
    def records(params = {}, **)
      Internal::Record.list(object: api_slug || id, **params, **)
    end

    # Create a record for this object
    def create_record(values = {}, **)
      Internal::Record.create(object: api_slug || id, values: values, **)
    end

    # Find by attribute using Rails-style syntax
    def self.find_by(**conditions)
      # Extract any opts that aren't conditions
      opts = {}
      known_opts = [:api_key, :timeout, :idempotency_key]
      known_opts.each do |opt|
        opts[opt] = conditions.delete(opt) if conditions.key?(opt)
      end
      
      # Currently only supports slug
      if conditions.key?(:slug)
        slug = conditions[:slug]
        begin
          retrieve(slug, **opts)
        rescue NotFoundError
          list(**opts).find { |obj| obj.api_slug == slug }
        end
      else
        raise ArgumentError, "find_by only supports slug attribute for objects"
      end
    end
    
    # Find by API slug (deprecated - use find_by(slug: ...) instead)
    def self.find_by_slug(slug, **opts)
      find_by(slug: slug, **opts)
    end

    # Get standard objects
    def self.people(**)
      find_by_slug("people", **)
    end

    # Get the standard Companies object
    # @return [Object] The companies object
    def self.companies(**)
      find_by_slug("companies", **)
    end
  end
end
