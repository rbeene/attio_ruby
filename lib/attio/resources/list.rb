# frozen_string_literal: true

require_relative "../api_resource"

module Attio
  # Represents an Attio List
  #
  # Lists are collections of records from a specific object type.
  # They provide a way to organize and filter records.
  #
  # @example Create a new list
  #   list = Attio::List.create(
  #     name: "VIP Customers",
  #     object: "people",
  #     workspace_access: "full-access"
  #   )
  #
  # @example Add records to a list
  #   list.add_record("rec_123")
  #
  # @example Get all entries in a list
  #   entries = list.entries
  #   entries.each { |entry| puts entry["record_id"] }
  class List < APIResource
    api_operations :list, :retrieve, :create, :update

    def self.resource_path
      "lists"
    end

    # Define known attributes with proper accessors
    attr_attio :name, :workspace_access

    # Read-only attributes
    attr_reader :api_slug, :attio_object_id, :object_api_slug,
      :created_by_actor, :workspace_id

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

      updated = self.class.update(list_id: extract_id, **changed_attributes, **opts)
      update_from(updated.instance_variable_get(:@attributes)) if updated
      reset_changes!
      self
    end

    def save_create(**opts)
      # List requires object and name at minimum
      unless self[:object] && self[:name]
        raise InvalidRequestError, "Cannot save a new list without 'object' and 'name' attributes"
      end

      # Prepare all attributes for creation - only include non-nil values
      create_params = {
        object: self[:object],
        name: self[:name]
      }
      create_params[:api_slug] = self[:api_slug] if self[:api_slug]
      create_params[:workspace_access] = self[:workspace_access] if self[:workspace_access]
      create_params[:workspace_member_access] = self[:workspace_member_access] if self[:workspace_member_access]

      created = self.class.create(**create_params, **opts)

      if created
        @id = created.id
        @created_at = created.created_at
        update_from(created.instance_variable_get(:@attributes))
        reset_changes!
        self
      else
        raise InvalidRequestError, "Failed to create list"
      end
    end

    public

    # Lists cannot be deleted via API
    def destroy(**opts)
      raise NotImplementedError, "Lists cannot be deleted via the Attio API"
    end

    # Get all entries in this list
    # @param params [Hash] Query parameters
    # @param opts [Hash] Additional options
    # @return [Array<Hash>] List entries
    # @example Get all entries
    #   entries = list.entries
    # @example Get entries with pagination
    #   entries = list.entries(limit: 50, cursor: "next_page_cursor")
    def entries(**params)
      list_id = extract_id
      # Extract opts from params
      opts = params.slice(:client, :api_key)
      query_params = params.except(:client, :api_key)

      path = Util::PathBuilder.build_resource_path("lists", list_id, "entries")
      response = self.class.execute_request(HTTPMethods::GET, path, query_params, opts)
      response["data"] || []
    end

    # Add a record to this list
    # @param record_id [String] The ID of the record to add
    # @param opts [Hash] Additional options
    # @return [Hash] The created list entry
    # @example Add a person to the VIP list
    #   entry = list.add_record(record_id: "rec_123")
    def add_record(record_id:, **opts)
      list_id = extract_id
      path = Util::PathBuilder.build_resource_path("lists", list_id, "entries")
      self.class.execute_request(HTTPMethods::POST, path, {record_id: record_id}, opts)
    end

    # Remove a record from this list
    # @param entry_id [String] The ID of the list entry to remove (not the record ID)
    # @param opts [Hash] Additional options
    # @return [nil]
    # @note This requires the entry_id, not the record_id
    # @example Remove an entry from the list
    #   list.remove_record(entry_id: "ent_456")
    def remove_record(entry_id:, **opts)
      list_id = extract_id
      path = Util::PathBuilder.build_resource_path("lists", list_id, "entries", entry_id)
      self.class.execute_request(HTTPMethods::DELETE, path, {}, opts)
      nil
    end

    # Check if a record is in this list
    def contains_record?(record_id:, **opts)
      entries(record_id: record_id, **opts).any?
    end

    # Get the count of entries
    def entry_count(**)
      # Just get the entries and count them
      entries(**).length
    end

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
      # Override id_key to use list_id
      def id_key
        :list_id
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
            workspace_access: params[:workspace_access] || WorkspaceAccess::FULL_ACCESS,
            workspace_member_access: params[:workspace_member_access] || []
          }
        }
      end

      # Override update to handle data wrapper
      def prepare_params_for_update(params)
        {
          data: params
        }
      end

      # Find a list by its API slug
      # @param slug [String] The API slug of the list
      # @param opts [Hash] Additional options
      # @return [List] The found list
      # @raise [NotFoundError] If no list with the given slug is found
      # @example Find the VIP customers list
      #   list = Attio::List.find_by_slug(slug: "vip_customers")
      def find_by_slug(slug:, **opts)
        list(**opts).find { |lst| lst.api_slug == slug } ||
          raise(NotFoundError, "List with slug '#{slug}' not found")
      end

      # Get lists for a specific object type
      # @param object [String] The object type (e.g., "people", "companies")
      # @param params [Hash] Query parameters
      # @param opts [Hash] Additional options
      # @return [ListObject] Paginated list of lists
      # @example Get all lists for people
      #   people_lists = Attio::List.for_object(object: "people")
      def for_object(object:, **params)
        list(params.merge(object: object))
      end

      private

      def validate_object_identifier!(object)
        raise ArgumentError, "Object identifier is required" if object.nil? || object.to_s.empty?
      end
    end
  end
end
