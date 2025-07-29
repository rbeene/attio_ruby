# frozen_string_literal: true

module Attio
  module Util
    # Centralized ID extraction utility for handling various ID formats
    # across different Attio resources
    class IdExtractor
      class << self
        # Extract an ID from various formats
        # @param id [String, Hash, nil] The ID in various formats
        # @param key [Symbol, String] The key to extract from a hash ID
        # @return [String, nil] The extracted ID
        def extract(id, key = nil)
          return nil if id.nil?

          case id
          when String
            id
          when Hash
            extract_from_hash(id, key)
          else
            id.to_s if id.respond_to?(:to_s)
          end
        end

        # Extract a specific ID type from a potentially nested structure
        # @param id [String, Hash, nil] The ID structure
        # @param resource_type [Symbol] The resource type (:record, :webhook, :attribute, etc.)
        # @return [String, nil] The extracted ID
        def extract_for_resource(id, resource_type)
          return nil if id.nil?

          key = resource_key_map[resource_type]
          return id if id.is_a?(String) && key.nil?

          extract(id, key)
        end

        # Normalize an ID structure to a consistent format
        # @param id [String, Hash, nil] The ID to normalize
        # @param resource_type [Symbol] The resource type
        # @return [Hash, String, nil] The normalized ID
        def normalize(id, resource_type)
          return nil if id.nil?

          extracted = extract_for_resource(id, resource_type)
          return nil if extracted.nil?

          # For resources that need hash format
          if hash_format_resources.include?(resource_type)
            key = resource_key_map[resource_type]
            key ? {key => extracted} : extracted
          else
            extracted
          end
        end

        private

        def extract_from_hash(hash, key = nil)
          return nil unless hash.is_a?(Hash)

          if key
            # Try both symbol and string keys
            hash[key] || hash[key.to_s] || hash[key.to_sym]
          else
            # Try common ID keys in order of preference
            common_keys.each do |k|
              value = hash[k] || hash[k.to_s]
              return value if value
            end
            nil
          end
        end

        def resource_key_map
          @resource_key_map ||= {
            record: :record_id,
            workspace_member: :workspace_member_id,
            webhook: :webhook_id,
            attribute: :attribute_id,
            object: :object_id,
            list: :list_id,
            note: :note_id,
            comment: :comment_id,
            task: :task_id,
            entry: :entry_id,
            thread: :thread_id
          }.freeze
        end

        def hash_format_resources
          @hash_format_resources ||= %i[record].freeze
        end

        def common_keys
          @common_keys ||= %i[
            id
            record_id
            workspace_member_id
            webhook_id
            attribute_id
            object_id
            list_id
            note_id
            comment_id
            task_id
            entry_id
            thread_id
          ].freeze
        end
      end
    end
  end
end
