# frozen_string_literal: true

require_relative "../api_resource"

module Attio
  class Entry < APIResource
    attr_reader :parent_record_id, :parent_object, :list_id
    attr_accessor :entry_values

    def initialize(attributes = {}, opts = {})
      super

      normalized_attrs = normalize_attributes(attributes)

      # Extract specific entry attributes
      @parent_record_id = normalized_attrs[:parent_record_id]
      @parent_object = normalized_attrs[:parent_object]
      @entry_values = normalized_attrs[:entry_values] || {}

      # Extract list_id from nested ID structure
      if normalized_attrs[:id].is_a?(Hash)
        @list_id = normalized_attrs[:id][:list_id]
      end
    end

    class << self
      def resource_path
        "lists"
      end

      # Override id_key to use entry_id
      def id_key
        :entry_id
      end

      # List entries for a list
      def list(list: nil, **params)
        validate_list_identifier!(list)

        path = Util::PathBuilder.build_resource_path(resource_path, list, "entries", "query")
        response = execute_request(HTTPMethods::POST, path, params, {})
        APIResource::ListObject.new(response, self, params.merge(list: list), params)
      end
      alias_method :all, :list

      # Create a new entry
      def create(list: nil, parent_record_id: nil, parent_object: nil, entry_values: nil, **opts)
        validate_list_identifier!(list)
        validate_parent_params!(parent_record_id, parent_object)

        request_params = {
          data: {
            parent_record_id: parent_record_id,
            parent_object: parent_object,
            entry_values: entry_values || {}
          }
        }

        path = Util::PathBuilder.build_resource_path(resource_path, list, "entries")
        response = execute_request(HTTPMethods::POST, path, request_params, opts)
        new(response["data"] || response, opts)
      end

      # Retrieve a specific entry
      def retrieve(list: nil, entry_id: nil, **opts)
        validate_list_identifier!(list)
        validate_entry_id!(entry_id)

        path = Util::PathBuilder.build_resource_path(resource_path, list, "entries", entry_id)
        response = execute_request(HTTPMethods::GET, path, {}, opts)
        new(response["data"] || response, opts)
      end
      alias_method :get, :retrieve
      alias_method :find, :retrieve

      # Update an entry
      def update(list: nil, entry_id: nil, entry_values: nil, mode: nil, **opts)
        validate_list_identifier!(list)
        validate_entry_id!(entry_id)

        request_params = {
          data: {
            entry_values: entry_values || {}
          }
        }

        # Add mode parameter for append operations
        if mode == "append"
          request_params[:mode] = "append"
        end

        path = Util::PathBuilder.build_resource_path(resource_path, list, "entries", entry_id)
        response = execute_request(HTTPMethods::PATCH, path, request_params, opts)
        new(response["data"] || response, opts)
      end

      # Delete an entry
      def delete(list: nil, entry_id: nil, **opts)
        validate_list_identifier!(list)
        validate_entry_id!(entry_id)

        path = Util::PathBuilder.build_resource_path(resource_path, list, "entries", entry_id)
        execute_request(HTTPMethods::DELETE, path, {}, opts)
        true
      end
      alias_method :destroy, :delete

      # Assert an entry by parent record
      def assert_by_parent(list: nil, parent_record_id: nil, parent_object: nil, entry_values: nil, **opts)
        validate_list_identifier!(list)
        validate_parent_params!(parent_record_id, parent_object)

        request_params = {
          data: {
            parent_record_id: parent_record_id,
            parent_object: parent_object,
            entry_values: entry_values || {}
          }
        }

        path = Util::PathBuilder.build_resource_path(resource_path, list, "entries")
        response = execute_request(HTTPMethods::PUT, path, request_params, opts)
        new(response["data"] || response, opts)
      end

      # List attribute values for an entry
      def list_attribute_values(list: nil, entry_id: nil, attribute_id: nil, **opts)
        validate_list_identifier!(list)
        validate_entry_id!(entry_id)
        raise ArgumentError, "Attribute ID is required" if attribute_id.nil? || attribute_id.to_s.empty?

        path = Util::PathBuilder.build_resource_path(resource_path, list, "entries", entry_id, "attributes", attribute_id, "values")
        response = execute_request(HTTPMethods::GET, path, {}, opts)
        response["data"] || []
      end

      private

      def validate_list_identifier!(list)
        raise ArgumentError, "List identifier is required" if list.nil? || list.to_s.empty?
      end

      def validate_entry_id!(entry_id)
        raise ArgumentError, "Entry ID is required" if entry_id.nil? || entry_id.to_s.empty?
      end

      def validate_parent_params!(parent_record_id, parent_object)
        if parent_record_id.nil? || parent_object.nil?
          raise ArgumentError, "parent_record_id and parent_object are required"
        end
      end
    end

    # Instance methods

    def save(**opts)
      if persisted?
        save_update(**opts)
      else
        save_create(**opts)
      end
    end

    protected

    def save_update(**opts)
      raise InvalidRequestError, "Cannot save without list context" unless list_id

      # For Entry, we always save the full entry_values
      params = {
        data: {
          entry_values: entry_values
        }
      }

      response = self.class.execute_request(HTTPMethods::PATCH, resource_path, params, opts)
      update_from(response[:data] || response)
      reset_changes!
      self
    end

    def save_create(**opts)
      # Entry requires list, parent_record_id, and parent_object at minimum
      unless list_id && parent_record_id && parent_object
        raise InvalidRequestError, "Cannot save a new entry without 'list_id', 'parent_record_id', and 'parent_object' attributes"
      end

      # Prepare all attributes for creation
      create_params = {
        list: list_id,
        parent_record_id: parent_record_id,
        parent_object: parent_object,
        entry_values: entry_values || {}
      }

      created = self.class.create(**create_params, **opts)

      if created
        @id = created.id
        @created_at = created.created_at
        update_from(created.instance_variable_get(:@attributes))
        reset_changes!
        self
      else
        raise InvalidRequestError, "Failed to create entry"
      end
    end

    public

    def destroy(**opts)
      raise InvalidRequestError, "Cannot destroy an entry without an ID" unless persisted?
      raise InvalidRequestError, "Cannot destroy without list context" unless list_id

      self.class.execute_request(HTTPMethods::DELETE, "lists/#{list_id}/entries/#{extract_id}", {}, opts)
      @attributes.clear
      @changed_attributes.clear
      @id = nil
      true
    end

    # Override path building for complex resource paths
    def build_resource_path
      validate_context!("list", list_id)
      Util::PathBuilder.build_resource_path("lists", list_id, "entries", extract_id)
    end

    private

    def to_h
      {
        id: id,
        parent_record_id: parent_record_id,
        parent_object: parent_object,
        created_at: created_at&.iso8601,
        entry_values: entry_values
      }.compact
    end

    def inspect
      "#<#{self.class.name}:#{object_id} id=#{id.inspect} parent=#{parent_object}##{parent_record_id} values=#{entry_values.inspect}>"
    end
  end
end
