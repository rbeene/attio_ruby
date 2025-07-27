# frozen_string_literal: true

require_relative "../api_resource"

module Attio
  class Object < APIResource
    api_operations :list, :retrieve, :create, :update, :delete

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
    def attributes(**opts)
      Attribute.list(parent_object: api_slug || id, **opts)
    end

    # Create a new attribute for this object
    def create_attribute(params = {}, **opts)
      Attribute.create(params.merge(parent_object: api_slug || id), **opts)
    end

    # Get records for this object
    def records(params = {}, **opts)
      Record.list(object: api_slug || id, **params, **opts)
    end

    # Create a record for this object
    def create_record(values = {}, **opts)
      Record.create(object: api_slug || id, values: values, **opts)
    end

    # Find by API slug
    def self.find_by_slug(slug, **opts)
      retrieve(slug, **opts)
    rescue NotFoundError
      list(**opts).find { |obj| obj.api_slug == slug }
    end

    # Get standard objects
    def self.people(**opts)
      find_by_slug("people", **opts)
    end

    def self.companies(**opts)
      find_by_slug("companies", **opts)
    end
  end
end
