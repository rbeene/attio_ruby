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
        alias get retrieve
        alias find retrieve

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
      alias reload refresh

      private

      def update_from(attributes)
        @attributes.clear
        @original_attributes.clear
        @changed_attributes.clear
        
        attributes.each do |key, value|
          next if %w[id created_at _metadata].include?(key.to_s)
          
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