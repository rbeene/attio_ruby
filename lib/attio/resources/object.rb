# frozen_string_literal: true

require_relative "base"
require_relative "../api_operations/list"
require_relative "../api_operations/retrieve"
require_relative "../api_operations/create"
require_relative "../api_operations/update"

module Attio
  class Object < Resources::Base
    include APIOperations::List
    include APIOperations::Retrieve
    include APIOperations::Create
    include APIOperations::Update

    def self.resource_path
      "/objects"
    end

    attr_reader :api_slug, :singular_noun, :plural_noun, :created_by_actor

    def initialize(attributes = {}, opts = {})
      super
      @api_slug = attributes[:api_slug] || attributes["api_slug"]
      @singular_noun = attributes[:singular_noun] || attributes["singular_noun"]
      @plural_noun = attributes[:plural_noun] || attributes["plural_noun"]
      @created_by_actor = attributes[:created_by_actor] || attributes["created_by_actor"]
    end

    # Get all attributes for this object
    def attributes
      @attributes_cache ||= Attribute.list(object: api_slug || id)
    end

    # Create a new attribute for this object
    def create_attribute(params = {})
      Attribute.create(params.merge(object: api_slug || id))
    end

    # Get records for this object
    def records(params = {})
      Record.list(params.merge(object: api_slug || id))
    end

    # Create a record for this object
    def create_record(values = {})
      Record.create(object: api_slug || id, values: values)
    end

    # Update object configuration
    def save(opts = {})
      if id.nil?
        raise Errors::InvalidRequestError, "Cannot update an object without an ID"
      end

      params = {
        singular_noun: singular_noun,
        plural_noun: plural_noun
      }.compact

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
        api_slug: api_slug,
        singular_noun: singular_noun,
        plural_noun: plural_noun,
        created_by_actor: created_by_actor
      ).compact
    end

    class << self
      # Find object by API slug
      def find_by_slug(slug, opts = {})
        list(opts).find { |obj| obj.api_slug == slug } ||
          raise(Errors::NotFoundError, "Object with slug '#{slug}' not found")
      end

      # Get standard objects (people, companies)
      def people(opts = {})
        find_by_slug("people", opts)
      end

      def companies(opts = {})
        find_by_slug("companies", opts)
      end

      private

      def prepare_params(params)
        # Ensure proper format for object creation
        params
      end
    end
  end
end
