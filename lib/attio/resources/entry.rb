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

      # List entries for a list
      def list(list: nil, **params)
        validate_list_identifier!(list)

        response = execute_request(:POST, "#{resource_path}/#{list}/entries/query", params, {})
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

        response = execute_request(:POST, "#{resource_path}/#{list}/entries", request_params, opts)
        new(response["data"] || response, opts)
      end

      # Retrieve a specific entry
      def retrieve(list: nil, entry_id: nil, **opts)
        validate_list_identifier!(list)
        validate_entry_id!(entry_id)

        response = execute_request(:GET, "#{resource_path}/#{list}/entries/#{entry_id}", {}, opts)
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

        response = execute_request(:PATCH, "#{resource_path}/#{list}/entries/#{entry_id}", request_params, opts)
        new(response["data"] || response, opts)
      end

      # Delete an entry
      def delete(list: nil, entry_id: nil, **opts)
        validate_list_identifier!(list)
        validate_entry_id!(entry_id)

        execute_request(:DELETE, "#{resource_path}/#{list}/entries/#{entry_id}", {}, opts)
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

        response = execute_request(:PUT, "#{resource_path}/#{list}/entries", request_params, opts)
        new(response["data"] || response, opts)
      end

      # List attribute values for an entry
      def list_attribute_values(list: nil, entry_id: nil, attribute_id: nil, **opts)
        validate_list_identifier!(list)
        validate_entry_id!(entry_id)
        raise ArgumentError, "Attribute ID is required" if attribute_id.nil? || attribute_id.to_s.empty?

        response = execute_request(:GET, "#{resource_path}/#{list}/entries/#{entry_id}/attributes/#{attribute_id}/values", {}, opts)
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
      raise InvalidRequestError, "Cannot save an entry without an ID" unless persisted?
      raise InvalidRequestError, "Cannot save without list context" unless list_id

      # For Entry, we always save the full entry_values
      params = {
        data: {
          entry_values: entry_values
        }
      }

      response = self.class.execute_request(:PATCH, resource_path, params, opts)
      update_from(response[:data] || response)
      reset_changes!
      self
    end

    def destroy(**opts)
      raise InvalidRequestError, "Cannot destroy an entry without an ID" unless persisted?
      raise InvalidRequestError, "Cannot destroy without list context" unless list_id

      entry_id = extract_entry_id
      self.class.execute_request(:DELETE, "lists/#{list_id}/entries/#{entry_id}", {}, opts)
      @attributes.clear
      @changed_attributes.clear
      @id = nil
      true
    end

    def resource_path
      raise InvalidRequestError, "Cannot generate path without list context" unless list_id
      entry_id = extract_entry_id
      "lists/#{list_id}/entries/#{entry_id}"
    end

    private

    def extract_entry_id
      case id
      when Hash
        id[:entry_id] || id["entry_id"]
      else
        id
      end
    end

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
