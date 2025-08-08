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
      # Supports Rails-style hash syntax: find_by(name: "Test")
      def find_by(**conditions)
        raise ArgumentError, "find_by requires at least one condition" if conditions.empty?

        # Extract any opts that aren't conditions (like api_key)
        opts = {}
        known_opts = [:api_key, :timeout, :idempotency_key]
        known_opts.each do |opt|
          opts[opt] = conditions.delete(opt) if conditions.key?(opt)
        end

        # Build filter from conditions
        filters = []
        search_query = nil

        conditions.each do |field, value|
          # Check if there's a special filter method for this field
          filter_method = "filter_by_#{field}"
          if respond_to?(filter_method, true) # true = include private methods
            result = send(filter_method, value)
            # Check if this should be a search instead of a filter
            if result == :use_search
              search_query = value
            else
              filters << result
            end
          else
            # Use the field as-is
            filters << {field => value}
          end
        end

        # If we have a search query, use search instead of filter
        if search_query
          search(search_query, **opts).first
        else
          # Combine multiple filters with $and if needed
          final_filter = if filters.length == 1
            filters.first
          elsif filters.length > 1
            {"$and": filters}
          else
            {}
          end

          list(**opts.merge(params: {
            filter: final_filter
          })).first
        end
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
      super
    end
  end
end
