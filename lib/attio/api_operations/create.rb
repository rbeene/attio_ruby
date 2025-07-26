# frozen_string_literal: true

module Attio
  module APIOperations
    module Create
      module ClassMethods
        def create(params = {}, opts = {})
          validate_params!(params)

          request = RequestBuilder.build(
            method: :POST,
            path: resource_path,
            params: prepare_params(params),
            headers: opts[:headers] || {},
            api_key: opts[:api_key]
          )

          response = connection_manager.execute(request)
          parsed = ResponseParser.parse(response, request)

          construct_from(parsed, opts)
        end

        private

        def validate_params!(params)
          return if params.is_a?(Hash)
          raise ArgumentError, "Parameters must be a Hash, got #{params.class}"
        end

        def prepare_params(params)
          # Subclasses can override to prepare params
          params
        end

        def construct_from(response, opts = {})
          new(response, opts)
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
