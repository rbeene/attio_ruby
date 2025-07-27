# frozen_string_literal: true

module Attio
  # Base class for all API resources
  # Provides standard CRUD operations in a clean, Ruby-like way
  class APIResource
    include Enumerable

    attr_reader :id, :created_at, :metadata

    def initialize(attributes = {}, opts = {})
      @attributes = {}
      @original_attributes = {}
      @changed_attributes = Set.new
      @opts = opts
      @metadata = {}

      # Normalize attributes to use symbol keys
      normalized_attrs = normalize_attributes(attributes)

      # Extract metadata and system fields
      if normalized_attrs.is_a?(Hash)
        # Handle Attio's nested ID structure
        @id = extract_id(normalized_attrs[:id])
        @created_at = parse_timestamp(normalized_attrs[:created_at])
        @metadata = normalized_attrs[:_metadata] || {}

        # Process all attributes
        skip_keys = %i[id created_at _metadata]
        normalized_attrs.each do |key, value|
          next if skip_keys.include?(key)

          @attributes[key] = process_attribute_value(value)
          @original_attributes[key] = deep_copy(process_attribute_value(value))
        end
      end
    end

    # Attribute access
    def [](key)
      @attributes[key.to_sym]
    end

    def []=(key, value)
      key = key.to_sym
      old_value = @attributes[key]
      new_value = process_attribute_value(value)

      return if old_value == new_value

      @attributes[key] = new_value
      @changed_attributes.add(key)
    end

    def fetch(key, default = nil)
      @attributes.fetch(key.to_sym, default)
    end

    def key?(key)
      @attributes.key?(key.to_sym)
    end
    alias_method :has_key?, :key?
    alias_method :include?, :key?

    # Dirty tracking
    def changed?
      !@changed_attributes.empty?
    end

    def changed
      @changed_attributes.map(&:to_s)
    end

    def changes
      @changed_attributes.each_with_object({}) do |key, hash|
        hash[key.to_s] = [@original_attributes[key], @attributes[key]]
      end
    end

    def changed_attributes
      @changed_attributes.each_with_object({}) do |key, hash|
        hash[key] = @attributes[key]
      end
    end

    def reset_changes!
      @changed_attributes.clear
      @original_attributes = deep_copy(@attributes)
    end

    def revert!
      @attributes = deep_copy(@original_attributes)
      @changed_attributes.clear
    end

    # Serialization
    def to_h
      {
        id: id,
        created_at: created_at&.iso8601,
        **@attributes
      }.compact
    end
    alias_method :to_hash, :to_h

    def to_json(*args)
      JSON.generate(to_h, *args)
    end

    def inspect
      attrs = @attributes.map { |k, v| "#{k}: #{v.inspect}" }.join(", ")
      "#<#{self.class.name}:#{object_id} id=#{id.inspect} #{attrs}>"
    end

    # Enumerable support
    def each(&block)
      return enum_for(:each) unless block_given?
      @attributes.each(&block)
    end

    def keys
      @attributes.keys
    end

    def values
      @attributes.values
    end

    # Comparison
    def ==(other)
      other.is_a?(self.class) && id == other.id && @attributes == other.instance_variable_get(:@attributes)
    end
    alias_method :eql?, :==

    def hash
      [self.class, id, @attributes].hash
    end

    # Update attributes
    def update_attributes(attributes)
      attributes.each do |key, value|
        self[key] = value
      end
      self
    end

    # Check if resource has been persisted
    def persisted?
      !id.nil?
    end

    # Update from API response
    def update_from(response)
      normalized = normalize_attributes(response)
      @id = normalized[:id] if normalized[:id]
      @created_at = parse_timestamp(normalized[:created_at]) if normalized[:created_at]
      
      normalized.each do |key, value|
        next if %i[id created_at _metadata].include?(key)
        @attributes[key] = process_attribute_value(value)
      end
      
      reset_changes!
      self
    end

    # Resource path helpers
    def self.resource_path
      raise NotImplementedError, "Subclasses must implement resource_path"
    end

    def self.resource_name
      name.split("::").last.downcase
    end

    def resource_path
      "#{self.class.resource_path}/#{id}"
    end

    # Default save implementation
    def save(**opts)
      if persisted?
        self.class.update(id, changed_attributes, **opts)
      else
        raise InvalidRequestError, "Cannot save a resource without an ID"
      end
    end

    # Default destroy implementation
    def destroy(**opts)
      raise InvalidRequestError, "Cannot destroy a resource without an ID" unless persisted?
      self.class.delete(id, **opts)
      true
    end
    alias_method :delete, :destroy

    class << self
      # Define which operations this resource supports
      # Example: api_operations :list, :create, :retrieve, :update, :delete
      def api_operations(*operations)
        @supported_operations = operations
        
        operations.each do |operation|
          case operation
          when :list
            define_list_operation
          when :create
            define_create_operation
          when :retrieve
            define_retrieve_operation
          when :update
            define_update_operation
          when :delete
            define_delete_operation
          else
            raise ArgumentError, "Unknown operation: #{operation}"
          end
        end
      end

      # Define attribute accessors for known attributes
      def attr_attio(*attributes)
        attributes.each do |attr|
          # Reader method
          define_method(attr) do
            self[attr]
          end

          # Writer method
          define_method("#{attr}=") do |value|
            self[attr] = value
          end

          # Predicate method
          define_method("#{attr}?") do
            !!self[attr]
          end
        end
      end

      # Execute HTTP request
      def execute_request(method, path, params = {}, opts = {})
        client = Attio.client(api_key: opts[:api_key])
        
        case method
        when :GET
          client.get(path, params)
        when :POST
          client.post(path, params)
        when :PUT
          client.put(path, params)
        when :PATCH
          client.patch(path, params)
        when :DELETE
          client.delete(path)
        else
          raise ArgumentError, "Unsupported method: #{method}"
        end
      end

      # Get the ID parameter name (usually "id", but sometimes needs prefix)
      def id_param_name(id = nil)
        :id
      end

      # Validate an ID parameter
      def validate_id!(id)
        raise ArgumentError, "ID is required" if id.nil? || id.to_s.empty?
      end

      # Hook for subclasses to prepare params before create
      def prepare_params_for_create(params)
        params
      end

      # Hook for subclasses to prepare params before update
      def prepare_params_for_update(params)
        params
      end

      private

      def define_list_operation
        define_singleton_method :list do |params = {}, **opts|
          response = execute_request(:GET, resource_path, params, opts)
          ListObject.new(response, self, params, opts)
        end
        
        singleton_class.send(:alias_method, :all, :list)
      end

      def define_create_operation
        define_singleton_method :create do |params = {}, **opts|
          prepared_params = prepare_params_for_create(params)
          response = execute_request(:POST, resource_path, prepared_params, opts)
          new(response["data"] || response, opts)
        end
      end

      def define_retrieve_operation
        define_singleton_method :retrieve do |id, **opts|
          validate_id!(id)
          response = execute_request(:GET, "#{resource_path}/#{id}", {}, opts)
          new(response["data"] || response, opts)
        end
        
        singleton_class.send(:alias_method, :get, :retrieve)
        singleton_class.send(:alias_method, :find, :retrieve)
      end

      def define_update_operation
        define_singleton_method :update do |id, params = {}, **opts|
          validate_id!(id)
          prepared_params = prepare_params_for_update(params)
          response = execute_request(:PATCH, "#{resource_path}/#{id}", prepared_params, opts)
          new(response[:data] || response, opts)
        end
      end

      def define_delete_operation
        define_singleton_method :delete do |id, **opts|
          validate_id!(id)
          execute_request(:DELETE, "#{resource_path}/#{id}", {}, opts)
          true
        end
        
        singleton_class.send(:alias_method, :destroy, :delete)
      end
    end

    # ListObject for handling paginated responses
    class ListObject
      include Enumerable

      attr_reader :data, :has_more, :cursor, :resource_class

      def initialize(response, resource_class, params = {}, opts = {})
        @resource_class = resource_class
        @params = params
        @opts = opts
        @data = []
        @has_more = false
        @cursor = nil

        if response.is_a?(Hash)
          raw_data = response["data"] || []
          @data = raw_data.map { |attrs| resource_class.new(attrs, opts) }
          @has_more = response["has_more"] || false
          @cursor = response["cursor"]
        end
      end

      def each(&block)
        @data.each(&block)
      end

      def empty?
        @data.empty?
      end

      def length
        @data.length
      end
      alias_method :size, :length
      alias_method :count, :length

      def first
        @data.first
      end

      def last
        @data.last
      end

      def [](index)
        @data[index]
      end

      def next_page
        return nil unless has_more? && cursor

        @resource_class.list(@params.merge(cursor: cursor), **@opts)
      end

      def has_more?
        @has_more == true
      end

      def auto_paging_each(&block)
        return enum_for(:auto_paging_each) unless block_given?

        page = self
        loop do
          page.each(&block)
          break unless page.has_more?
          page = page.next_page
          break unless page
        end
      end

      def to_a
        @data
      end

      def inspect
        "#<#{self.class.name} data=#{@data.inspect} has_more=#{@has_more}>"
      end
    end

    protected

    def normalize_attributes(attributes)
      return attributes unless attributes.is_a?(Hash)
      attributes.transform_keys(&:to_sym)
    end

    def process_attribute_value(value)
      case value
      when Hash
        if value.key?(:value) || value.key?("value")
          # Handle Attio attribute format
          value[:value] || value["value"]
        else
          # Regular hash
          value.transform_keys(&:to_sym)
        end
      when Array
        value.map { |v| process_attribute_value(v) }
      else
        value
      end
    end

    def parse_timestamp(value)
      return nil if value.nil?

      case value
      when Time
        value
      when String
        Time.parse(value)
      when Integer
        Time.at(value)
      end
    rescue ArgumentError
      nil
    end

    def extract_id(id_value)
      case id_value
      when Hash
        # Handle Attio's nested ID structure
        # Objects have { workspace_id: "...", object_id: "..." }
        # Records have { workspace_id: "...", object_id: "...", record_id: "..." }
        id_value
      when String
        # Simple string ID
        id_value
      else
        id_value
      end
    end

    def deep_copy(obj)
      case obj
      when Hash
        obj.transform_values { |v| deep_copy(v) }
      when Array
        obj.map { |v| deep_copy(v) }
      when Set
        Set.new(obj.map { |v| deep_copy(v) })
      else
        begin
          obj.dup
        rescue
          obj
        end
      end
    end
  end
end