# frozen_string_literal: true

require_relative "../api_resource"

module Attio
  class Record < APIResource
    # Record doesn't use standard CRUD operations due to object parameter requirement
    # We'll define custom methods instead
    api_operations :delete

    def self.resource_path
      "objects"
    end

    # Override id_key to use record_id
    def self.id_key
      :record_id
    end

    attr_reader :attio_object_id, :object_api_slug

    def initialize(attributes = {}, opts = {})
      super

      normalized_attrs = normalize_attributes(attributes)

      # Extract object_id from nested ID if present
      if @id.is_a?(Hash)
        @attio_object_id = @id["object_id"] || @id[:object_id]
      end

      @attio_object_id ||= normalized_attrs[:object_id]
      @object_api_slug = normalized_attrs[:object_api_slug]

      # Process values into attributes
      if normalized_attrs[:values]
        process_values(normalized_attrs[:values])
      end
    end

    class << self
      # List records for an object with optional filtering, sorting, and pagination
      # @param object [String] The object type (e.g., "people", "companies")
      # @param opts [Hash] Query options
      # @option opts [String] :q Search query
      # @option opts [Hash] :filter Filter conditions
      # @option opts [Array<Hash>] :sort Sort order
      # @option opts [Integer] :limit Number of records per page
      # @option opts [String] :cursor Pagination cursor
      # @return [ListObject] Paginated list of records
      # @example List all people
      #   people = Attio::Record.list(object: "people")
      # @example Search and filter
      #   executives = Attio::Record.list(
      #     object: "people",
      #     q: "CEO",
      #     filter: { company_size: { "$gte": 100 } },
      #     sort: [{ attribute: "created_at", direction: "desc" }],
      #     limit: 25
      #   )
      def list(object:, **opts)
        validate_object_identifier!(object)

        # Extract query parameters from opts
        query_params = build_query_params(opts)

        path = Util::PathBuilder.build_resource_path(resource_path, object, "records", "query")
        response = execute_request(HTTPMethods::POST, path, query_params, opts)

        APIResource::ListObject.new(response, self, opts.merge(object: object), opts)
      end
      alias_method :all, :list

      # Create a new record
      # @param object [String] The object type (e.g., "people", "companies")
      # @param values [Hash] The attribute values for the record
      # @param opts [Hash] Additional options
      # @return [Record] The created record
      # @raise [ArgumentError] If object or values are missing/invalid
      # @example Create a person
      #   person = Attio::Record.create(
      #     object: "people",
      #     values: {
      #       name: "John Doe",
      #       email_addresses: "john@example.com"
      #     }
      #   )
      def create(object:, values:, **opts)
        validate_object_identifier!(object)
        validate_values!(values)

        request_params = {
          data: {
            values: normalize_values(values)
          }
        }

        path = Util::PathBuilder.build_resource_path(resource_path, object, "records")
        response = execute_request(HTTPMethods::POST, path, request_params, opts)

        # Ensure object info is included
        record_data = response["data"] || {}
        record_data[:object_api_slug] ||= object if record_data.is_a?(Hash)

        new(record_data, opts)
      end

      # Retrieve a specific record
      # @param record_id [String, Hash] The record ID (string or nested hash with record_id key)
      # @param object [String] The object type (e.g., "people", "companies")
      # @param opts [Hash] Additional options
      # @return [Record] The retrieved record
      # @raise [ArgumentError] If record_id or object are missing
      # @raise [NotFoundError] If the record doesn't exist
      # @example Retrieve a person
      #   person = Attio::Record.retrieve(
      #     record_id: "rec_456def789",
      #     object: "people"
      #   )
      def retrieve(record_id:, object:, **opts)
        validate_object_identifier!(object)

        # Extract simple ID if it's a nested hash
        # Extract simple ID from potentially nested structure
        simple_record_id = record_id.is_a?(Hash) ? (record_id["record_id"] || record_id[:record_id]) : record_id
        validate_id!(simple_record_id)

        path = Util::PathBuilder.build_resource_path(resource_path, object, "records", simple_record_id)
        response = execute_request(HTTPMethods::GET, path, {}, opts)

        record_data = response["data"] || {}
        record_data[:object_api_slug] ||= object

        new(record_data, opts)
      end
      alias_method :get, :retrieve
      alias_method :find, :retrieve

      # Update a record
      # @param record_id [String, Hash] The record ID (string or nested hash with record_id key)
      # @param object [String] The object type (e.g., "people", "companies")
      # @param values [Hash] The attribute values to update
      # @param opts [Hash] Additional options
      # @return [Record] The updated record
      # @raise [ArgumentError] If record_id, object, or values are missing
      # @example Update a person's job title
      #   person = Attio::Record.update(
      #     record_id: "rec_456def789",
      #     object: "people",
      #     values: { job_title: "Senior Engineer" }
      #   )
      def update(record_id:, object:, values:, **opts)
        validate_object_identifier!(object)
        validate_values!(values)

        # Extract simple ID if it's a nested hash
        # Extract simple ID from potentially nested structure
        simple_record_id = record_id.is_a?(Hash) ? (record_id["record_id"] || record_id[:record_id]) : record_id
        validate_id!(simple_record_id)

        request_params = {
          data: {
            values: normalize_values(values)
          }
        }

        path = Util::PathBuilder.build_resource_path(resource_path, object, "records", simple_record_id)
        response = execute_request(HTTPMethods::PUT, path, request_params, opts)

        record_data = response["data"] || {}
        record_data[:object_api_slug] ||= object

        new(record_data, opts)
      end

      # Search records
      # @param query [String] The search query
      # @param object [String] The object type to search
      # @param opts [Hash] Additional options
      # @return [ListObject] Paginated list of matching records
      # @example Search for people named John
      #   results = Attio::Record.search("John", object: "people")
      def search(query, object:, **opts)
        list(object: object, q: query, **opts)
      end

      # Delete a record
      # @param record_id [String, Hash] The record ID
      # @param object [String] The object type
      # @param opts [Hash] Additional options
      # @return [Boolean] True if deletion was successful
      # @raise [ArgumentError] If record_id or object are missing
      # @example Delete a person
      #   Attio::Record.delete(record_id: "rec_123", object: "people")
      def delete(record_id:, object:, **opts)
        validate_object_identifier!(object)
        # Extract simple ID from potentially nested structure
        simple_record_id = record_id.is_a?(Hash) ? (record_id["record_id"] || record_id[:record_id]) : record_id
        validate_id!(simple_record_id)

        path = Util::PathBuilder.build_resource_path(resource_path, object, "records", simple_record_id)
        execute_request(HTTPMethods::DELETE, path, {}, opts)
        true
      end
      alias_method :destroy, :delete

      # Batch delete records
      # @param object [String] The object type
      # @param record_ids [Array<String, Hash>] Array of record IDs to delete
      # @param opts [Hash] Additional options
      # @return [Hash] Result summary with :deleted and :failed keys
      # @example Delete multiple people
      #   result = Attio::Record.batch_delete(
      #     object: "people",
      #     record_ids: ["rec_123", "rec_456", "rec_789"]
      #   )
      #   puts "Deleted: #{result[:deleted]}, Failed: #{result[:failed].count}"
      def batch_delete(object:, record_ids:, **opts)
        validate_object_identifier!(object)
        raise ArgumentError, "record_ids must be an array" unless record_ids.is_a?(Array)
        raise ArgumentError, "record_ids cannot be empty" if record_ids.empty?

        deleted = []
        failed = []

        record_ids.each do |record_id|
          delete(record_id: record_id, object: object, **opts)
          deleted << record_id
        rescue => e
          failed << {record_id: record_id, error: e.message}
        end

        {deleted: deleted, failed: failed}
      end

      private

      def validate_object_identifier!(object)
        raise ArgumentError, "Object identifier is required" if object.nil? || object.to_s.empty?
      end

      def validate_values!(values)
        raise ArgumentError, "Values must be a Hash" unless values.is_a?(Hash)
      end

      # ID extraction is now handled by the base class extract_id method

      def build_query_params(params)
        query_params = {}

        query_params[:filter] = build_filter(params[:filter]) if params[:filter]
        query_params[:sort] = build_sort(params[:sort]) if params[:sort]
        query_params[:limit] = params[:limit] if params[:limit]
        query_params[:cursor] = params[:cursor] if params[:cursor]
        query_params[:q] = params[:q] if params[:q]

        query_params
      end

      def build_filter(filter)
        case filter
        when Hash
          filter
        when Array
          {"$and" => filter}
        else
          filter
        end
      end

      def build_sort(sort)
        case sort
        when String
          parse_sort_string(sort)
        when Hash
          sort
        else
          sort
        end
      end

      def parse_sort_string(sort_string)
        field, direction = sort_string.split(":")
        {
          field: field,
          direction: direction || "asc"
        }
      end

      def normalize_values(values)
        values.transform_values do |value|
          case value
          when Array
            value.map { |v| normalize_single_value(v) }
          else
            normalize_single_value(value)
          end
        end
      end

      def normalize_single_value(value)
        case value
        when Hash
          value
        when NilClass
          nil
        else
          value
        end
      end
    end

    # Instance methods

    # Save changes to the record or create a new one
    # @param opts [Hash] Additional options
    # @option opts [Boolean] :partial (true) Whether to send only changed fields (update only)
    # @return [self] The updated or created record
    # @raise [InvalidRequestError] If the record cannot be saved
    def save(**opts)
      if persisted?
        save_update(**opts)
      else
        save_create(**opts)
      end
    end

    protected

    def save_update(**opts)
      raise InvalidRequestError, "Cannot save without object context" unless object_api_slug
      return self unless changed?

      # Use PATCH for partial updates (default) or PUT for full replacement
      method = opts.fetch(:partial, true) ? :PATCH : :PUT
      params = {
        data: {
          values: prepare_values_for_update(partial: opts.fetch(:partial, true))
        }
      }

      response = self.class.execute_request(method, resource_path, params, opts)

      update_from(response["data"] || response[:data] || response)
      reset_changes!
      self
    end

    def save_create(**opts)
      # Record requires object context for creation
      unless object_api_slug
        raise InvalidRequestError, "Cannot save a new record without object context. Set the object_api_slug attribute or use Record.create"
      end

      # Get all values for creation
      values = @attributes.except(:id, :created_at, :object_id, :object_api_slug, :values)

      created = self.class.create(object: object_api_slug, values: values, **opts)

      if created
        @id = created.id
        @created_at = created.created_at
        update_from(created.instance_variable_get(:@attributes))
        reset_changes!
        self
      else
        raise InvalidRequestError, "Failed to create record"
      end
    end

    public

    # Add this record to a list
    def add_to_list(list_id, **)
      list = List.retrieve(list_id, **)
      list.add_record(record_id: id, **)
    end

    # Get lists containing this record
    def lists(**)
      raise InvalidRequestError, "Cannot get lists without an ID" unless persisted?

      # This is a simplified implementation - in reality you'd need to query the API
      # for lists that contain this record
      List.list(record_id: id, **)
    end

    # Override path building for complex resource paths
    def build_resource_path
      validate_context!("object", object_api_slug)
      Util::PathBuilder.build_resource_path(self.class.resource_path, object_api_slug, "records", extract_id)
    end

    # Override destroy to use correct path
    def destroy(**opts)
      raise InvalidRequestError, "Cannot destroy a record without an ID" unless persisted?
      raise InvalidRequestError, "Cannot destroy without object context" unless object_api_slug

      self.class.execute_request(HTTPMethods::DELETE, resource_path, {}, opts)
      @attributes.clear
      @changed_attributes.clear
      @id = nil
      true
    end

    def to_h
      values_hash = @attributes.except(:id, :created_at, :object_id, :object_api_slug, :values)

      result = {
        id: id,
        object_api_slug: object_api_slug,
        created_at: created_at&.iso8601,
        values: values_hash
      }

      # Add object_id if available
      result[:object_id] = attio_object_id if attio_object_id

      result.compact
    end

    def inspect
      values_preview = @attributes.take(3).map { |k, v| "#{k}: #{v.inspect}" }.join(", ")
      values_preview += "..." if @attributes.size > 3

      "#<#{self.class.name}:#{object_id} id=#{id.inspect} object=#{object_api_slug.inspect} values={#{values_preview}}>"
    end

    private

    def process_values(values)
      return unless values.is_a?(Hash)

      values.each do |key, value_data|
        extracted_value = extract_value(value_data)
        @attributes[key.to_sym] = extracted_value
        @original_attributes[key.to_sym] = deep_copy(extracted_value)
      end
    end

    def extract_value(value_data)
      case value_data
      when Array
        extracted = value_data.map { |v| extract_single_value(v) }
        (extracted.length == 1) ? extracted.first : extracted
      else
        extract_single_value(value_data)
      end
    end

    def extract_single_value(value_data)
      case value_data
      when Hash
        if value_data.key?(:value) || value_data.key?("value")
          value_data[:value] || value_data["value"]
        elsif value_data.key?(:target_object) || value_data.key?("target_object")
          # Reference value
          value_data[:target_object] || value_data["target_object"]
        else
          value_data
        end
      else
        value_data
      end
    end

    def prepare_values_for_update(partial: true)
      attrs = partial ? changed_attributes : @attributes
      attrs.transform_values do |value|
        self.class.send(:normalize_values, {key: value})[:key]
      end
    end
  end
end
