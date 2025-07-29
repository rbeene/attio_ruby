# frozen_string_literal: true

require_relative "../internal/record"

module Attio
  # Base class for type-specific record classes (e.g., Person, Company)
  # Provides a more object-oriented interface for working with specific Attio objects
  class TypedRecord < Internal::Record
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
        super(object: object_type, values: values, **opts)
      end

      # Override update to automatically include object type
      def update(record_id, values: {}, **opts)
        super(object: object_type, record_id: record_id, data: {values: values}, **opts)
      end

      # Override delete to automatically include object type
      def delete(record_id, **opts)
        # The parent delete expects object in opts for records
        simple_id = record_id.is_a?(Hash) ? record_id["record_id"] : record_id
        execute_request(:DELETE, "objects/#{object_type}/records/#{simple_id}", {}, opts)
        true
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

      # Just call the parent destroy method which handles everything correctly
      super(**opts)
    end
  end
end
