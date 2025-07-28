# frozen_string_literal: true

require "cgi"
require_relative "util/path_builder"

module Attio
  # Base class for all API resources
  #
  # This class provides a foundation for all Attio API resources with:
  # - Attribute management with dirty tracking
  # - Automatic API operation generation
  # - Serialization and deserialization
  # - Enumerable interface for iterating attributes
  # - Thread-safe operations
  #
  # @abstract Subclass and use {.api_operations} to define available operations
  class APIResource
    include Enumerable

    # @return [String, Hash] The resource's unique identifier
    attr_reader :id

    # @return [Time, nil] When the resource was created
    attr_reader :created_at

    # @return [Hash] Additional metadata from the API
    attr_reader :metadata

    SKIP_KEYS = %i[id created_at _metadata].freeze

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
        @id = normalized_attrs[:id]
        @created_at = parse_timestamp(normalized_attrs[:created_at])
        @metadata = normalized_attrs[:_metadata] || {}

        # Process all attributes
        normalized_attrs.each do |key, value|
          next if SKIP_KEYS.include?(key)

          @attributes[key] = process_attribute_value(value)
          @original_attributes[key] = deep_copy(process_attribute_value(value))
        end
      end
    end

    # Get an attribute value
    # @param key [String, Symbol] The attribute name
    # @return [Object, nil] The attribute value
    def [](key)
      @attributes[key.to_sym]
    end

    # Set an attribute value
    # @param key [String, Symbol] The attribute name
    # @param value [Object] The new value
    # @return [Object] The new value
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

    # Check if any attributes have been modified
    # @return [Boolean] true if any attributes have changed
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

    # Convert the resource to a hash
    # @return [Hash] The resource as a hash
    def to_h
      {
        id: id,
        created_at: created_at&.iso8601,
        **@attributes
      }.compact
    end
    alias_method :to_hash, :to_h

    def to_json(*)
      JSON.generate(to_h, *)
    end

    def inspect
      attrs = @attributes.map { |k, v| "#{k}: #{v.inspect}" }.join(", ")
      "#<#{self.class.name}:#{object_id} id=#{id.inspect} #{attrs}>"
    end

    # Enumerable support
    def each(&)
      return enum_for(:each) unless block_given?
      @attributes.each(&)
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

    # Update multiple attributes at once
    # @param attributes [Hash] The attributes to update
    # @return [self]
    def update_attributes(attributes)
      attributes.each do |key, value|
        self[key] = value
      end
      self
    end

    # Check if the resource exists in the API
    # @return [Boolean] true if the resource has an ID
    def persisted?
      !id.nil?
    end

    # Update from API response
    def update_from(response)
      normalized = normalize_attributes(response)
      @id = normalized[:id] if normalized[:id]
      @created_at = parse_timestamp(normalized[:created_at]) if normalized[:created_at]

      normalized.each do |key, value|
        next if SKIP_KEYS.include?(key)
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
      raise InvalidRequestError, "Cannot generate path without an ID" unless persisted?

      # Allow subclasses to override path generation
      if respond_to?(:build_resource_path, true)
        build_resource_path
      else
        extracted_id = extract_id
        Util::PathBuilder.build_resource_path(self.class.resource_path, extracted_id)
      end
    end

    # Extract ID from potentially nested hash structure
    # @param id_type [Symbol, String] Optional specific ID type to extract
    # @return [String] The extracted ID
    def extract_id(id_type = nil)
      return id unless id.is_a?(Hash)

      if id_type
        id[id_type.to_sym] || id[id_type.to_s]
      else
        # Use the class's id_key if no type specified
        key = self.class.id_key
        id[key] || id[key.to_s]
      end
    end

    # Validation helpers
    def validate_persisted!
      raise InvalidRequestError, "Cannot perform operation without an ID" unless persisted?
    end

    def validate_context!(context_name, context_value)
      if context_value.nil? || context_value.to_s.empty?
        raise InvalidRequestError, "Cannot perform operation without #{context_name} context"
      end
    end

    # Default save implementation
    # Subclasses should override save_create to handle creation
    def save(**opts)
      if persisted?
        save_update(**opts)
      else
        save_create(**opts)
      end
    end

    protected

    # Handle updating an existing resource
    def save_update(**opts)
      return self unless changed?

      if self.class.respond_to?(:update)
        updated = self.class.update(id, changed_attributes, **opts)
        update_from(updated.instance_variable_get(:@attributes)) if updated
        reset_changes!
        self
      else
        raise InvalidRequestError, "This resource type does not support updates"
      end
    end

    # Handle creating a new resource
    # Subclasses should override this to provide resource-specific creation logic
    def save_create(**opts)
      raise InvalidRequestError, "Cannot save a new #{self.class.name} - creation not implemented. Use #{self.class.name}.create instead."
    end

    public

    # Default destroy implementation
    def destroy(**)
      raise InvalidRequestError, "Cannot destroy a resource without an ID" unless persisted?
      self.class.delete(id, **)
      true
    end
    alias_method :delete, :destroy

    class << self
      # Define which API operations this resource supports
      #
      # @param operations [Array<Symbol>] List of operations (:list, :create, :retrieve, :update, :delete)
      # @example Define all CRUD operations
      #   api_operations :list, :create, :retrieve, :update, :delete
      # @example Define read-only operations
      #   api_operations :list, :retrieve
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

      # Define Attio-specific attribute accessors
      #
      # Creates getter, setter, and predicate methods for each attribute
      #
      # @param attributes [Array<Symbol>] List of attribute names
      # @example
      #   attr_attio :name, :email, :phone
      #   # Creates: #name, #name=, #name?
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

      # Get the ID parameter key for this resource
      # Subclasses can override this to use specific keys like :record_id, :note_id, etc.
      def id_key
        :id
      end

      private

      def define_list_operation
        define_singleton_method :list do |params = {}, **opts|
          response = execute_request(HTTPMethods::GET, resource_path, params, opts)
          ListObject.new(response, self, params, opts)
        end

        singleton_class.send(:alias_method, :all, :list)
      end

      def define_create_operation
        define_singleton_method :create do |params = {}, **opts|
          prepared_params = prepare_params_for_create(params)
          response = execute_request(HTTPMethods::POST, resource_path, prepared_params, opts)
          new(response["data"] || response, opts)
        end
      end

      def define_retrieve_operation
        define_singleton_method :retrieve do |id = nil, **opts|
          # Support both positional and keyword arguments
          actual_id = id || opts.delete(id_key)
          validate_id!(actual_id)
          path = Util::PathBuilder.build_resource_path(resource_path, actual_id)
          response = execute_request(HTTPMethods::GET, path, {}, opts)
          new(response["data"] || response, opts)
        end

        singleton_class.send(:alias_method, :get, :retrieve)
        singleton_class.send(:alias_method, :find, :retrieve)
      end

      def define_update_operation
        define_singleton_method :update do |id = nil, params = nil, **opts|
          # Support both positional and keyword arguments
          if id.nil? && params.nil? && !opts.empty?
            # Called with keyword arguments only: update(list_id: "123", name: "value")
            all_params = opts
            actual_id = all_params.delete(id_key) || all_params.delete(:id)
            params = all_params
            opts = {}
          elsif id.is_a?(Hash) && params.nil?
            # Called with single hash argument: update({list_id: "123", name: "value"})
            all_params = id.merge(opts)
            actual_id = all_params.delete(id_key) || all_params.delete(:id)
            params = all_params
            opts = {}
          else
            # Called with positional arguments: update("123", {name: "value"})
            actual_id = id
            params ||= {}
          end

          validate_id!(actual_id)
          prepared_params = prepare_params_for_update(params)
          path = Util::PathBuilder.build_resource_path(resource_path, actual_id)
          response = execute_request(HTTPMethods::PATCH, path, prepared_params, opts)
          new(response["data"] || response[:data] || response, opts)
        end
      end

      def define_delete_operation
        define_singleton_method :delete do |id = nil, **opts|
          # Support both positional and keyword arguments
          actual_id = id || opts.delete(id_key)
          validate_id!(actual_id)
          path = Util::PathBuilder.build_resource_path(resource_path, actual_id)
          execute_request(HTTPMethods::DELETE, path, {}, opts)
          true
        end

        singleton_class.send(:alias_method, :destroy, :delete)
      end
    end

    # Handles paginated API responses
    #
    # Provides enumerable interface for paginated data with support for:
    # - Manual pagination via {#next_page}
    # - Automatic pagination via {#auto_paging_each}
    # - Standard collection methods (first, last, [], etc.)
    #
    # @example Manual pagination
    #   page = Attio::Record.list(object: "people", limit: 25)
    #   while page.has_more?
    #     page.each { |record| puts record.name }
    #     page = page.next_page
    #   end
    #
    # @example Auto-pagination with memory safety
    #   Attio::Record.list(object: "people").auto_paging_each do |record|
    #     process_record(record)
    #   end
    class ListObject
      include Enumerable

      # @return [Array<APIResource>] The current page of resources
      attr_reader :data

      # @return [Boolean] Whether more pages are available
      attr_reader :has_more

      # @return [String, nil] Cursor for fetching the next page
      attr_reader :cursor

      # @return [Class] The resource class for items in this list
      attr_reader :resource_class

      # @api private
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

      def each(&)
        @data.each(&)
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

      # Fetch the next page of results
      # @return [ListObject, nil] The next page, or nil if no more pages
      def next_page
        return nil unless has_more? && cursor

        @resource_class.list(@params.merge(cursor: cursor), **@opts)
      end

      # Check if more pages are available
      # @return [Boolean]
      def has_more?
        @has_more == true
      end

      # Iterate through all pages automatically
      #
      # This method fetches pages on-demand to avoid loading
      # the entire dataset into memory at once.
      #
      # @yield [APIResource] Each resource across all pages
      # @return [Enumerator] If no block given
      # @example Process all records without loading into memory
      #   records.auto_paging_each do |record|
      #     process_record(record)
      #   end
      # @example Convert to array (loads all into memory - use with caution)
      #   all_records = records.auto_paging_each.to_a
      def auto_paging_each(&block)
        return enum_for(:auto_paging_each) unless block_given?

        page = self
        page_count = 0
        max_pages = 1000 # Safety limit to prevent infinite loops

        loop do
          page.each(&block)
          break unless page.has_more?

          page_count += 1
          if page_count >= max_pages
            warn "[Attio] Auto-pagination stopped after #{max_pages} pages to prevent potential infinite loop"
            break
          end

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

    # This method was moved to instance methods section above

    def deep_copy(obj)
      # Skip deep copy for immutable objects
      return obj if obj.nil? || obj.is_a?(TrueClass) || obj.is_a?(FalseClass) ||
        obj.is_a?(Numeric) || obj.is_a?(Symbol)

      case obj
      when String
        # Strings might be frozen, so we dup them
        obj.frozen? ? obj : obj.dup
      when Hash
        obj.transform_values { |v| deep_copy(v) }
      when Array
        obj.map { |v| deep_copy(v) }
      when Set
        Set.new(obj.map { |v| deep_copy(v) })
      else
        # Only attempt to dup if the object supports it
        obj.respond_to?(:dup) ? obj.dup : obj
      end
    rescue
      # If anything goes wrong, return the original object
      obj
    end
  end
end
