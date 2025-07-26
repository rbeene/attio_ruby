# frozen_string_literal: true

module Attio
  module Resources
    class Base
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
          @id = normalized_attrs[:id]
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

      # API interaction helpers
      def request(method:, path: nil, params: nil, headers: {})
        path ||= resource_path

        request = RequestBuilder.build(
          method: method,
          path: path,
          params: params,
          headers: headers,
          api_key: @opts[:api_key]
        )

        response = connection_manager.execute(request)
        Util::ResponseParser.parse(response, request)
      end

      def connection_manager
        @connection_manager ||= Util::ConnectionManager.new
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

      # Dynamic attribute methods
      def method_missing(method_name, *args, &block)
        method_string = method_name.to_s

        if method_string.end_with?("=")
          # Setter method
          attribute_name = method_string[0...-1].to_sym
          self[attribute_name] = args.first
        elsif method_string.end_with?("?")
          # Predicate method
          attribute_name = method_string[0...-1].to_sym
          !!self[attribute_name]
        elsif @attributes.key?(method_name)
          # Getter method
          self[method_name]
        else
          super
        end
      end

      def respond_to_missing?(method_name, include_private = false)
        method_string = method_name.to_s

        if method_string.end_with?("=", "?")
          true
        elsif @attributes.key?(method_name)
          true
        else
          super
        end
      end
    end
  end
end
