# frozen_string_literal: true

module Attio
  module APIOperations
    module Retrieve
      module ClassMethods
        def retrieve(id, opts = {})
          validate_id!(id)

          request = RequestBuilder.build(
            method: :GET,
            path: "#{resource_path}/#{id}",
            headers: opts[:headers] || {},
            api_key: opts[:api_key]
          )

          response = connection_manager.execute(request)
          parsed = ResponseParser.parse(response, request)

          construct_from(parsed, opts)
        end
        alias_method :get, :retrieve
        alias_method :find, :retrieve

        private

        def validate_id!(id)
          raise ArgumentError, "ID is required" if id.nil? || id.to_s.empty?
        end

        def construct_from(response, opts = {})
          new(response, opts)
        end

        def connection_manager
          @connection_manager ||= Util::ConnectionManager.new
        end
      end

      def self.included(base)
        base.extend(ClassMethods)
      end

      def refresh
        request = RequestBuilder.build(
          method: :GET,
          path: resource_path,
          headers: @opts[:headers] || {},
          api_key: @opts[:api_key]
        )

        response = connection_manager.execute(request)
        parsed = ResponseParser.parse(response, request)

        update_from(parsed)
        self
      end
      alias_method :reload, :refresh

      private

      def update_from(attributes)
        @attributes.clear
        @original_attributes.clear
        @changed_attributes.clear

        normalized_attrs = normalize_attributes(attributes)
        skip_keys = %i[id created_at _metadata]
        normalized_attrs.each do |key, value|
          next if skip_keys.include?(key)

          @attributes[key] = process_attribute_value(value)
          @original_attributes[key] = deep_copy(process_attribute_value(value))
        end

        @id = normalized_attrs[:id] if normalized_attrs[:id]
        @created_at = parse_timestamp(normalized_attrs[:created_at])
        @metadata = normalized_attrs[:_metadata] || {}
      end

      def normalize_attributes(attributes)
        return {} unless attributes

        attributes.each_with_object({}) do |(key, value), hash|
          hash[key.to_sym] = value
        end
      end
    end
  end
end
