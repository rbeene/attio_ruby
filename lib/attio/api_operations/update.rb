# frozen_string_literal: true

module Attio
  module APIOperations
    module Update
      def save(opts = {})
        if id.nil?
          raise InvalidRequestError, "Cannot update a resource without an ID"
        end

        params = changed? ? changed_attributes : @attributes

        request = RequestBuilder.build(
          method: :PATCH,
          path: resource_path,
          params: prepare_update_params(params),
          headers: opts[:headers] || {},
          api_key: opts[:api_key] || @opts[:api_key]
        )

        response = connection_manager.execute(request)
        parsed = ResponseParser.parse(response, request)

        update_from(parsed)
        reset_changes!
        self
      end
      alias_method :update, :save

      def update_attributes(attributes, opts = {})
        attributes.each do |key, value|
          self[key] = value
        end
        save(opts)
      end

      def destroy(opts = {})
        if id.nil?
          raise InvalidRequestError, "Cannot delete a resource without an ID"
        end

        request = RequestBuilder.build(
          method: :DELETE,
          path: resource_path,
          headers: opts[:headers] || {},
          api_key: opts[:api_key] || @opts[:api_key]
        )

        response = connection_manager.execute(request)
        ResponseParser.parse(response, request)

        freeze
        true
      end
      alias_method :delete, :destroy

      private

      def prepare_update_params(params)
        # Subclasses can override to format params for updates
        params
      end

      def update_from(attributes)
        skip_keys = %w[id created_at _metadata]
        attributes.each do |key, value|
          next if skip_keys.include?(key.to_s)

          @attributes[key.to_sym] = process_attribute_value(value)
          @original_attributes[key.to_sym] = deep_copy(process_attribute_value(value))
        end

        @id = attributes[:id] || attributes["id"] if attributes[:id] || attributes["id"]
        @created_at = parse_timestamp(attributes[:created_at] || attributes["created_at"])
        @metadata = attributes[:_metadata] || attributes["_metadata"] || {}
      end
    end
  end
end
