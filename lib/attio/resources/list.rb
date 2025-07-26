# frozen_string_literal: true

require_relative "base"
require_relative "../api_operations/list"
require_relative "../api_operations/retrieve"
require_relative "../api_operations/create"
require_relative "../api_operations/update"
require_relative "../api_operations/delete"

module Attio
  class List < Resources::Base
    include APIOperations::List
    include APIOperations::Retrieve
    include APIOperations::Create
    include APIOperations::Update
    include APIOperations::Delete

    def self.resource_path
      "/lists"
    end

    attr_reader :api_slug, :name, :object_id, :object_api_slug,
                :created_by_actor, :workspace_id, :workspace_access

    def initialize(attributes = {}, opts = {})
      super
      @api_slug = attributes[:api_slug] || attributes["api_slug"]
      @name = attributes[:name] || attributes["name"]
      @object_id = attributes[:object_id] || attributes["object_id"]
      @object_api_slug = attributes[:object_api_slug] || attributes["object_api_slug"]
      @created_by_actor = attributes[:created_by_actor] || attributes["created_by_actor"]
      @workspace_id = attributes[:workspace_id] || attributes["workspace_id"]
      @workspace_access = attributes[:workspace_access] || attributes["workspace_access"]
    end

    # Get all entries in this list
    def entries(params = {}, opts = {})
      ListEntry.list({ list_id: id }.merge(params), opts)
    end

    # Add a record to this list
    def add_record(record_id, opts = {})
      ListEntry.create(list_id: id, record_id: record_id, opts: opts)
    end

    # Remove a record from this list
    def remove_record(entry_id, opts = {})
      ListEntry.delete(list_id: id, entry_id: entry_id, opts: opts)
    end

    # Check if a record is in this list
    def contains_record?(record_id, opts = {})
      entries({ record_id: record_id }, opts).any?
    end

    # Get the count of entries
    def entry_count(opts = {})
      entries({ limit: 1 }, opts).total_count
    end

    # Update list properties
    def save(opts = {})
      if id.nil?
        raise Errors::InvalidRequestError, "Cannot update a list without an ID"
      end

      params = {
        name: name,
        workspace_access: workspace_access
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
        name: name,
        object_id: object_id,
        object_api_slug: object_api_slug,
        created_by_actor: created_by_actor,
        workspace_id: workspace_id,
        workspace_access: workspace_access
      ).compact
    end

    class << self
      # Create a new list
      def create(name:, object:, workspace_access: nil, opts: {})
        validate_object_identifier!(object)
        
        params = {
          name: name,
          object: object,
          workspace_access: workspace_access
        }.compact
        
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

      # Find list by API slug
      def find_by_slug(slug, opts = {})
        list(opts).find { |lst| lst.api_slug == slug } ||
          raise(Errors::NotFoundError, "List with slug '#{slug}' not found")
      end

      # Get lists for a specific object
      def for_object(object, params = {}, opts = {})
        list(params.merge(object: object), opts)
      end

      private

      def validate_object_identifier!(object)
        raise ArgumentError, "Object identifier is required" if object.nil? || object.to_s.empty?
      end
    end
  end
end