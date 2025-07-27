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

    attr_reader :attio_object_id, :object_api_slug

    def initialize(attributes = {}, opts = {})
      super

      normalized_attrs = normalize_attributes(attributes)
      @attio_object_id = normalized_attrs[:object_id]
      @object_api_slug = normalized_attrs[:object_api_slug]

      # Process values into attributes
      if normalized_attrs[:values]
        process_values(normalized_attrs[:values])
      end
    end

    class << self
      # List records for an object
      def list(object:, **opts)
        validate_object_identifier!(object)

        # Extract query parameters from opts
        query_params = build_query_params(opts)

        response = execute_request(:POST, "#{resource_path}/#{object}/records/query", query_params, opts)

        APIResource::ListObject.new(response, self, opts.merge(object: object), opts)
      end
      alias_method :all, :list

      # Create a new record
      def create(object: nil, values: nil, data: nil, **opts)
        # Handle both parameter styles
        if values
          # Test style: create(object: "people", values: {...})
          validate_object_identifier!(object)
          validate_values!(values)
          normalized_values = values
        elsif data && data[:values]
          # API style: create(object: "people", data: { values: {...} })
          validate_object_identifier!(object)
          validate_values!(data[:values])
          normalized_values = data[:values]
        else
          raise ArgumentError, "Must provide object and either values or data.values"
        end

        request_params = {
          data: {
            values: normalize_values(normalized_values)
          }
        }

        response = execute_request(:POST, "#{resource_path}/#{object}/records", request_params, opts)

        # Ensure object info is included
        record_data = response["data"] || {}
        record_data[:object_api_slug] ||= object if record_data.is_a?(Hash)

        new(record_data, opts)
      end

      # Retrieve a specific record
      def retrieve(record_id: nil, object: nil, **opts)
        validate_object_identifier!(object)

        # Extract simple ID if it's a nested hash
        simple_record_id = record_id.is_a?(Hash) ? record_id["record_id"] : record_id
        validate_id!(simple_record_id)

        response = execute_request(:GET, "#{resource_path}/#{object}/records/#{simple_record_id}", {}, opts)

        record_data = response["data"] || {}
        record_data[:object_api_slug] ||= object

        new(record_data, opts)
      end
      alias_method :get, :retrieve
      alias_method :find, :retrieve

      # Update a record
      def update(record_id: nil, object: nil, data: nil, **opts)
        validate_object_identifier!(object)

        # Extract simple ID if it's a nested hash
        simple_record_id = record_id.is_a?(Hash) ? record_id["record_id"] : record_id
        validate_id!(simple_record_id)

        request_params = {
          data: {
            values: normalize_values(data[:values] || data)
          }
        }

        response = execute_request(:PUT, "#{resource_path}/#{object}/records/#{simple_record_id}", request_params, opts)

        record_data = response["data"] || {}
        record_data[:object_api_slug] ||= object

        new(record_data, opts)
      end

      # Batch create records
      def batch_create(object: nil, records: nil, **opts)
        validate_object_identifier!(object)
        validate_batch!(records)

        request_params = {
          data: records.map do |record|
            values = record[:data] ? record[:data][:values] : record[:values] || record
            {values: normalize_values(values)}
          end
        }

        response = execute_request(:POST, "records/batch", request_params, opts)

        (response["data"] || []).map do |record_data|
          record_data[:object_api_slug] ||= object if record_data.is_a?(Hash)
          new(record_data, opts)
        end
      end

      # Batch update records
      def batch_update(object: nil, records: nil, **opts)
        validate_object_identifier!(object)
        validate_batch!(records)

        request_params = {
          data: records.map do |record|
            record_id = record[:record_id] || record[:id]
            simple_record_id = record_id.is_a?(Hash) ? record_id["record_id"] : record_id

            values = record[:data] ? record[:data][:values] : record[:values]

            {
              id: {record_id: simple_record_id},
              values: normalize_values(values)
            }
          end
        }

        response = execute_request(:PUT, "records/batch", request_params, opts)

        (response["data"] || []).map do |record_data|
          record_data[:object_api_slug] ||= object if record_data.is_a?(Hash)
          new(record_data, opts)
        end
      end

      # Batch create records (legacy name)
      def create_batch(records:, object:, **opts)
        validate_object_identifier!(object)
        validate_batch!(records)

        params = {
          object: object,
          data: records.map { |r| {values: normalize_values(r[:values] || r)} }
        }

        response = execute_request(:POST, "#{resource_path}/batch", params, opts)

        (response["data"] || []).map do |record_data|
          record_data[:object_api_slug] ||= object if record_data.is_a?(Hash)
          new(record_data, opts)
        end
      end

      # Search records
      def search(query, object:, **)
        list({q: query}, object: object, **)
      end

      private

      def validate_object_identifier!(object)
        raise ArgumentError, "Object identifier is required" if object.nil? || object.to_s.empty?
      end

      def validate_values!(values)
        raise ArgumentError, "Values must be a Hash" unless values.is_a?(Hash)
      end

      def validate_batch!(records)
        raise ArgumentError, "Records must be an array" unless records.is_a?(Array)
        raise ArgumentError, "Records cannot be empty" if records.empty?
      end

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
          {value: value}
        end
      end
    end

    # Instance methods

    # Save changes to the record
    def save(**opts)
      raise InvalidRequestError, "Cannot update a record without an ID" unless persisted?
      raise InvalidRequestError, "Cannot save without object context" unless object_api_slug

      return self unless changed?

      params = {
        data: {
          values: prepare_values_for_update
        }
      }

      response = self.class.send(:execute_request, :PATCH, resource_path, params, opts)

      update_from(response[:data] || response)
      reset_changes!
      self
    end

    # Add this record to a list
    def add_to_list(list_id, **)
      list = List.retrieve(list_id, **)
      list.add_record(id, **)
    end

    # Get lists containing this record
    def lists(**)
      raise InvalidRequestError, "Cannot get lists without an ID" unless persisted?

      # This is a simplified implementation - in reality you'd need to query the API
      # for lists that contain this record
      List.list(record_id: id, **)
    end

    def resource_path
      raise InvalidRequestError, "Cannot generate path without object context" unless object_api_slug
      record_id = id.is_a?(Hash) ? id["record_id"] : id
      "#{self.class.resource_path}/#{object_api_slug}/records/#{record_id}"
    end

    # Override destroy to use correct path
    def destroy(**opts)
      raise InvalidRequestError, "Cannot destroy a record without an ID" unless persisted?
      raise InvalidRequestError, "Cannot destroy without object context" unless object_api_slug

      self.class.send(:execute_request, :DELETE, resource_path, {}, opts)
      @attributes.clear
      @changed_attributes.clear
      @id = nil
      true
    end

    def to_h
      values = @attributes.except(:id, :created_at, :object_id, :object_api_slug)

      {
        id: id,
        object_id: attio_object_id,
        object_api_slug: object_api_slug,
        created_at: created_at&.iso8601,
        values: values
      }.compact
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

    def prepare_values_for_update
      changed_attributes.transform_values do |value|
        self.class.send(:normalize_values, {key: value})[:key]
      end
    end
  end
end
