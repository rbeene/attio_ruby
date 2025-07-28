# frozen_string_literal: true

require_relative "record"

module Attio
  # Base class for type-specific record classes (e.g., Person, Company)
  # Provides a more object-oriented interface for working with specific Attio objects
  class TypedRecord < Record
    class << self
      # Define the object type for this class
      # @param type [String] The Attio object type (e.g., "people", "companies")
      def object_type(type = nil)
        if type
          @object_type = type
        else
          @object_type || raise(NotImplementedError, "#{self} must define object_type")
        end
      end

      # Override list to automatically include object type
      def list(**opts)
        super(object: object_type, **opts)
      end

      # Override retrieve to automatically include object type
      def retrieve(record_id, **opts)
        super(object: object_type, record_id: record_id, **opts)
      end

      # Override create to automatically include object type
      def create(values: {}, **opts)
        # Use the simple API endpoint that expects object in the payload
        prepared_params = prepare_params_for_create({
          object: object_type,
          values: values
        })

        response = execute_request(:POST, "records", prepared_params, opts)
        new(response["data"] || response, opts)
      end

      # Override update to automatically include object type
      def update(record_id, values: {}, **opts)
        super(object: object_type, record_id: record_id, values: values, **opts)
      end

      # Override delete to automatically include object type
      def delete(record_id:, **opts)
        super(object: object_type, record_id: record_id, **opts)
      end

      # Provide a more intuitive find method
      def find(record_id, **opts)
        retrieve(record_id, **opts)
      end

      # Provide a more intuitive all method
      def all(**opts)
        list(**opts)
      end

      # Search with a query string
      def search(query, **opts)
        list(**opts.merge(params: {q: query}))
      end

      # Find by a specific attribute value
      def find_by(attribute, value, **opts)
        list(**opts.merge(params: {
          filter: {
            attribute => value
          }
        })).first
      end

      private

      # Prepare parameters for create requests
      def prepare_params_for_create(params)
        {
          data: params
        }
      end
    end

    # Override initialize to ensure object type is set
    def initialize(attributes = {}, opts = {})
      super
      # Ensure the object type matches the class
      if respond_to?(:object) && object != self.class.object_type
        raise ArgumentError, "Object type mismatch: expected #{self.class.object_type}, got #{object}"
      end
    end

    # Override save to include object type
    def save(**opts)
      raise InvalidRequestError, "Cannot save without an ID" unless persisted?
      return self unless changed?

      self.class.update(id, values: changed_attributes, **opts)
    end

    # Override destroy to include object type
    def destroy(**opts)
      raise InvalidRequestError, "Cannot destroy without an ID" unless persisted?

      record_id = id.is_a?(Hash) ? id["record_id"] : id
      self.class.delete(record_id: record_id, **opts)
      freeze
      true
    end
  end
end
