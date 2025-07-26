# frozen_string_literal: true

module Attio
  module APIOperations
    module Delete
      module ClassMethods
        def delete(id, opts = {})
          validate_id!(id)

          request = RequestBuilder.build(
            method: :DELETE,
            path: "#{resource_path}/#{id}",
            headers: opts[:headers] || {},
            api_key: opts[:api_key]
          )

          response = connection_manager.execute(request)
          ResponseParser.parse(response, request)

          true
        end
        alias_method :destroy, :delete

        private

        def validate_id!(id)
          raise ArgumentError, "ID is required" if id.nil? || id.to_s.empty?
        end

        def connection_manager
          Attio.connection_manager
        end
      end

      def self.included(base)
        base.extend(ClassMethods)
      end
    end
  end
end
