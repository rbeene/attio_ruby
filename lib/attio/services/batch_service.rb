# frozen_string_literal: true

module Attio
  module Services
    class BatchService
      MAX_BATCH_SIZE = 100
      DEFAULT_CONCURRENCY = 5

      attr_reader :results, :options

      def initialize(options = {})
        @options = options
        @results = {
          success: [],
          errors: [],
          total: 0,
          processed: 0
        }
        @progress_callback = options[:on_progress]
        @error_callback = options[:on_error]
        @success_callback = options[:on_success]
      end

      # Execute multiple operations in batches
      def execute(operations, batch_size: MAX_BATCH_SIZE, concurrency: DEFAULT_CONCURRENCY)
        @results[:total] = operations.size

        operations.each_slice(batch_size).with_index do |batch, batch_index|
          process_batch(batch, batch_index)
        end

        @results
      end

      # Create multiple records across different objects
      def create_records(records_by_object, batch_size: MAX_BATCH_SIZE)
        operations = []

        records_by_object.each do |object_slug, records|
          records.each_slice(batch_size) do |batch|
            operations << {
              type: :create_batch,
              object: object_slug,
              records: batch
            }
          end
        end

        execute(operations)
      end

      # Update multiple records
      def update_records(updates, batch_size: MAX_BATCH_SIZE)
        operations = updates.map do |update|
          {
            type: :update,
            object: update[:object],
            record_id: update[:record_id],
            values: update[:values]
          }
        end

        execute(operations, batch_size: batch_size)
      end

      # Delete multiple records
      def delete_records(deletions, batch_size: MAX_BATCH_SIZE)
        operations = deletions.map do |deletion|
          {
            type: :delete,
            object: deletion[:object],
            record_id: deletion[:record_id]
          }
        end

        execute(operations, batch_size: batch_size)
      end

      # Mixed operations batch
      def mixed_operations(operations_list)
        validated_operations = operations_list.map do |op|
          validate_operation!(op)
          op
        end

        execute(validated_operations)
      end

      # Import data with deduplication
      def import_with_deduplication(object:, records:, unique_attribute:, batch_size: MAX_BATCH_SIZE)
        # First, get existing records
        existing = {}

        Record.list(object: object).auto_paging_each do |record|
          key = record[unique_attribute]
          existing[key] = record if key
        end

        # Separate new vs update operations
        operations = []

        records.each do |record_data|
          unique_value = record_data[:values][unique_attribute]

          operations << if existing[unique_value]
            # Update existing
            {
              type: :update,
              object: object,
              record_id: existing[unique_value].id,
              values: record_data[:values]
            }
          else
            # Create new
            {
              type: :create,
              object: object,
              values: record_data[:values]
            }
          end
        end

        execute(operations, batch_size: batch_size)
      end

      # Sync records (create, update, or delete to match source)
      def sync_records(object:, source_records:, match_attribute:, delete_missing: false)
        # Get all existing records
        existing = {}
        existing_ids = Set.new

        Record.list(object: object).auto_paging_each do |record|
          key = record[match_attribute]
          if key
            existing[key] = record
            existing_ids.add(record.id)
          end
        end

        # Build operations
        operations = []
        seen_keys = Set.new

        source_records.each do |source|
          key = source[:values][match_attribute]
          seen_keys.add(key)

          if existing[key]
            # Update existing
            operations << {
              type: :update,
              object: object,
              record_id: existing[key].id,
              values: source[:values]
            }
            existing_ids.delete(existing[key].id)
          else
            # Create new
            operations << {
              type: :create,
              object: object,
              values: source[:values]
            }
          end
        end

        # Delete missing records if requested
        if delete_missing
          existing_ids.each do |record_id|
            operations << {
              type: :delete,
              object: object,
              record_id: record_id
            }
          end
        end

        execute(operations)
      end

      private

      def process_batch(batch, batch_index)
        batch.each_with_index do |operation, index|
          result = execute_operation(operation)
          @results[:success] << {operation: operation, result: result}
          @results[:processed] += 1

          trigger_success_callback(operation, result)
          trigger_progress_callback
        rescue => e
          error_info = {
            operation: operation,
            error: e.message,
            error_class: e.class.name,
            batch_index: batch_index,
            operation_index: index
          }

          @results[:errors] << error_info
          @results[:processed] += 1

          trigger_error_callback(error_info)
          trigger_progress_callback

          # Re-raise if fail-fast mode
          raise e if @options[:fail_fast]
        end
      end

      def execute_operation(operation)
        case operation[:type]
        when :create
          Record.create(
            object: operation[:object],
            values: operation[:values]
          )
        when :create_batch
          Record.create_batch(
            object: operation[:object],
            records: operation[:records]
          )
        when :update
          record = Record.retrieve(
            object: operation[:object],
            record_id: operation[:record_id]
          )
          record.update_attributes(operation[:values])
        when :delete
          Record.delete(
            object: operation[:object],
            record_id: operation[:record_id]
          )
        when :add_to_list
          ListEntry.create(
            list_id: operation[:list_id],
            record_id: operation[:record_id]
          )
        when :remove_from_list
          ListEntry.delete(
            list_id: operation[:list_id],
            entry_id: operation[:entry_id]
          )
        else
          raise ArgumentError, "Unknown operation type: #{operation[:type]}"
        end
      end

      def validate_operation!(operation)
        unless operation[:type]
          raise ArgumentError, "Operation must have a type"
        end

        case operation[:type]
        when :create, :create_batch
          if !operation[:object] || (!operation[:values] && !operation[:records])
            raise ArgumentError, "Create operation requires object and values/records"
          end
        when :update
          unless operation[:object] && operation[:record_id] && operation[:values]
            raise ArgumentError, "Update operation requires object, record_id, and values"
          end
        when :delete
          unless operation[:object] && operation[:record_id]
            raise ArgumentError, "Delete operation requires object and record_id"
          end
        end
      end

      def trigger_progress_callback
        return unless @progress_callback

        progress = {
          processed: @results[:processed],
          total: @results[:total],
          success_count: @results[:success].size,
          error_count: @results[:errors].size,
          percentage: (@results[:processed].to_f / @results[:total] * 100).round(2)
        }

        @progress_callback.call(progress)
      end

      def trigger_error_callback(error_info)
        return unless @error_callback
        @error_callback.call(error_info)
      end

      def trigger_success_callback(operation, result)
        return unless @success_callback
        @success_callback.call(operation, result)
      end
    end
  end
end
