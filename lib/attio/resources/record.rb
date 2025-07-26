# frozen_string_literal: true

require_relative "base"
require_relative "../api_operations/list"
require_relative "../api_operations/retrieve"
require_relative "../api_operations/create"
require_relative "../api_operations/update"
require_relative "../api_operations/delete"

module Attio
  class Record < Resources::Base
    include APIOperations::Update
    include APIOperations::Delete

    def self.resource_path
      "/records"
    end

    attr_reader :object_id, :object_api_slug

    def initialize(attributes = {}, opts = {})
      super
      @object_id = attributes[:object_id] || attributes["object_id"]
      @object_api_slug = attributes[:object_api_slug] || attributes["object_api_slug"]
      
      # Process values into attributes
      if attributes[:values] || attributes["values"]
        process_values(attributes[:values] || attributes["values"])
      end
    end

    class << self
      # List records with filtering and sorting
      def list(object:, params = {}, opts = {})
        validate_object_identifier!(object)
        
        # Build query parameters
        query_params = build_query_params(params)
        
        request = RequestBuilder.build(
          method: :GET,
          path: "#{resource_path}/query",
          params: {
            object: object,
            **query_params
          },
          headers: opts[:headers] || {},
          api_key: opts[:api_key]
        )
        
        response = connection_manager.execute(request)
        parsed = ResponseParser.parse(response, request)
        
        APIOperations::List::ListObject.new(parsed, self, params.merge(object: object), opts)
      end
      alias all list

      # Create a new record
      def create(object:, values:, opts = {})
        validate_object_identifier!(object)
        validate_values!(values)
        
        request = RequestBuilder.build(
          method: :POST,
          path: resource_path,
          params: {
            data: {
              object: object,
              values: normalize_values(values)
            }
          },
          headers: opts[:headers] || {},
          api_key: opts[:api_key]
        )
        
        response = connection_manager.execute(request)
        parsed = ResponseParser.parse(response, request)
        
        new(parsed[:data], opts)
      end

      # Retrieve a specific record
      def retrieve(object:, record_id:, opts = {})
        validate_object_identifier!(object)
        validate_id!(record_id)
        
        request = RequestBuilder.build(
          method: :GET,
          path: "#{resource_path}/#{record_id}",
          params: { object: object },
          headers: opts[:headers] || {},
          api_key: opts[:api_key]
        )
        
        response = connection_manager.execute(request)
        parsed = ResponseParser.parse(response, request)
        
        new(parsed[:data], opts)
      end
      alias get retrieve
      alias find retrieve

      # Batch create records
      def create_batch(object:, records:, opts = {})
        validate_object_identifier!(object)
        raise ArgumentError, "Records must be an array" unless records.is_a?(Array)
        
        request = RequestBuilder.build(
          method: :POST,
          path: "#{resource_path}/batch",
          params: {
            object: object,
            data: records.map { |r| { values: normalize_values(r[:values] || r["values"]) } }
          },
          headers: opts[:headers] || {},
          api_key: opts[:api_key]
        )
        
        response = connection_manager.execute(request)
        parsed = ResponseParser.parse(response, request)
        
        parsed[:data].map { |record_data| new(record_data, opts) }
      end

      # Search records by attribute values
      def search(object:, query:, attributes: nil, opts = {})
        params = {
          q: query,
          attributes: attributes
        }.compact
        
        list(object: object, params: params, opts: opts)
      end

      private

      def validate_object_identifier!(object)
        raise ArgumentError, "Object identifier is required" if object.nil? || object.to_s.empty?
      end

      def validate_id!(id)
        raise ArgumentError, "Record ID is required" if id.nil? || id.to_s.empty?
      end

      def validate_values!(values)
        raise ArgumentError, "Values must be a hash" unless values.is_a?(Hash)
      end

      def normalize_values(values)
        values.transform_values do |value|
          case value
          when String, Numeric, TrueClass, FalseClass, NilClass
            # Wrap scalar values in Attio format
            { value: value }
          when Array
            # Handle array values (for multi-select, etc.)
            value.map { |v| normalize_single_value(v) }
          when Hash
            # Already in correct format or needs normalization
            if value.key?(:value) || value.key?("value")
              value
            else
              { value: value }
            end
          else
            { value: value.to_s }
          end
        end
      end

      def normalize_single_value(value)
        case value
        when Hash
          value
        else
          { value: value }
        end
      end

      def build_query_params(params)
        query_params = {}
        
        # Filtering
        if params[:filter]
          query_params[:filter] = build_filter(params[:filter])
        end
        
        # Sorting
        if params[:sort] || params[:order_by]
          query_params[:sort] = build_sort(params[:sort] || params[:order_by])
        end
        
        # Pagination
        query_params[:limit] = params[:limit] if params[:limit]
        query_params[:cursor] = params[:cursor] if params[:cursor]
        
        # Search
        query_params[:q] = params[:q] if params[:q]
        query_params[:attributes] = params[:attributes] if params[:attributes]
        
        query_params
      end

      def build_filter(filter)
        case filter
        when Hash
          filter
        when String
          # Parse simple filter strings like "status:active"
          parse_filter_string(filter)
        else
          filter
        end
      end

      def build_sort(sort)
        case sort
        when String
          # Handle "created_at:desc" format
          if sort.include?(":")
            field, direction = sort.split(":", 2)
            { field: field, direction: direction }
          else
            { field: sort, direction: "asc" }
          end
        when Hash
          sort
        when Array
          sort.map { |s| build_sort(s) }
        else
          sort
        end
      end

      def parse_filter_string(filter_string)
        # Simple parser for "attribute:value" format
        filters = {}
        filter_string.split(",").each do |condition|
          key, value = condition.split(":", 2)
          filters[key.strip] = value.strip if key && value
        end
        filters
      end
    end

    # Instance methods

    def save(opts = {})
      if id.nil?
        raise Errors::InvalidRequestError, "Cannot update a record without an ID"
      end

      params = {
        values: prepare_values_for_update
      }
      
      request = RequestBuilder.build(
        method: :PATCH,
        path: "#{self.class.resource_path}/#{id}",
        params: { data: params },
        headers: opts[:headers] || {},
        api_key: opts[:api_key] || @opts[:api_key]
      )
      
      response = connection_manager.execute(request)
      parsed = ResponseParser.parse(response, request)
      
      update_from(parsed[:data])
      reset_changes!
      self
    end

    # Get associated lists
    def lists
      List.list(record_id: id)
    end

    # Add to list
    def add_to_list(list_id)
      ListEntry.create(list_id: list_id, record_id: id)
    end

    # Remove from list
    def remove_from_list(list_id, entry_id)
      ListEntry.delete(list_id: list_id, entry_id: entry_id)
    end

    def to_h
      super.merge(
        object_id: object_id,
        object_api_slug: object_api_slug
      ).compact
    end

    private

    def process_values(values)
      values.each do |key, value_data|
        # Extract the actual value from Attio's format
        actual_value = extract_value(value_data)
        @attributes[key.to_sym] = actual_value
        @original_attributes[key.to_sym] = deep_copy(actual_value)
      end
    end

    def extract_value(value_data)
      case value_data
      when Hash
        if value_data.key?(:value) || value_data.key?("value")
          value_data[:value] || value_data["value"]
        elsif value_data.key?(:target_object) || value_data.key?("target_object")
          # Handle reference values
          value_data[:target_object] || value_data["target_object"]
        else
          value_data
        end
      when Array
        value_data.map { |v| extract_value(v) }
      else
        value_data
      end
    end

    def prepare_values_for_update
      changed_attributes.transform_values do |value|
        self.class.send(:normalize_values, { key: value })[:key]
      end
    end

    def resource_path
      "#{self.class.resource_path}/#{id}"
    end
  end
end