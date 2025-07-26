# frozen_string_literal: true

module Attio
  module Services
    class BaseService
      attr_reader :object_slug, :options

      def initialize(object_slug = nil, options = {})
        @object_slug = object_slug
        @options = options
        @transaction_records = []
        @in_transaction = false
      end

      # Transaction support
      def transaction(&block)
        raise ArgumentError, "Transaction requires a block" unless block_given?
        
        begin
          @in_transaction = true
          @transaction_records = []
          
          result = yield(self)
          
          # If we get here, transaction succeeded
          @in_transaction = false
          @transaction_records = []
          
          result
        rescue StandardError => e
          # Rollback on any error
          rollback!
          raise TransactionError, "Transaction failed: #{e.message}"
        ensure
          @in_transaction = false
        end
      end

      # Find or create a record by unique attribute
      def find_or_create_by(attribute:, value:, defaults: {})
        records = search_by_attribute(attribute, value)
        
        if records.any?
          records.first
        else
          create_params = defaults.merge(attribute => value)
          create_record(create_params)
        end
      end

      # Update or create a record
      def upsert(search_attribute:, search_value:, attributes: {})
        records = search_by_attribute(search_attribute, search_value)
        
        if records.any?
          record = records.first
          record.update_attributes(attributes)
          record
        else
          create_params = attributes.merge(search_attribute => search_value)
          create_record(create_params)
        end
      end

      # Bulk import records
      def import(records, batch_size: 100, on_error: :raise)
        results = {
          success: [],
          errors: []
        }
        
        records.each_slice(batch_size) do |batch|
          begin
            imported = Record.create_batch(object: object_slug, records: batch)
            results[:success].concat(imported)
          rescue StandardError => e
            case on_error
            when :raise
              raise e
            when :skip
              results[:errors].concat(batch.map { |r| { record: r, error: e.message } })
            when :continue
              # Try individual imports
              batch.each do |record_data|
                begin
                  imported = create_record(record_data[:values] || record_data)
                  results[:success] << imported
                rescue StandardError => individual_error
                  results[:errors] << { record: record_data, error: individual_error.message }
                end
              end
            end
          end
        end
        
        results
      end

      # Search with advanced filtering
      def search(query: nil, filters: {}, sort: nil, limit: nil)
        params = {}
        params[:q] = query if query
        params[:filter] = build_filters(filters) if filters.any?
        params[:sort] = sort if sort
        params[:limit] = limit if limit
        
        Record.list(object: object_slug, params: params)
      end

      # Get records by IDs
      def find_by_ids(ids)
        Array(ids).map do |id|
          Record.retrieve(object: object_slug, record_id: id)
        rescue Errors::NotFoundError
          nil
        end.compact
      end

      # Count records with optional filters
      def count(filters: {})
        # Use a minimal query to get just the count
        results = search(filters: filters, limit: 1)
        results.total_count
      end

      protected

      def object
        @object ||= Object.find_by_slug(object_slug) if object_slug
      end

      def create_record(values)
        record = Record.create(object: object_slug, values: values)
        track_transaction_record(record) if @in_transaction
        record
      end

      def search_by_attribute(attribute, value)
        Record.list(
          object: object_slug,
          params: {
            filter: { attribute => value }
          }
        )
      end

      def build_filters(filters)
        case filters
        when Hash
          filters
        when Array
          # Support array of filter conditions
          { "$and" => filters }
        else
          filters
        end
      end

      def track_transaction_record(record)
        @transaction_records << record
      end

      def rollback!
        return unless @transaction_records.any?
        
        @transaction_records.reverse_each do |record|
          begin
            record.destroy
          rescue StandardError => e
            # Log rollback failure but continue
            warn "Failed to rollback record #{record.id}: #{e.message}"
          end
        end
        
        @transaction_records = []
      end

      class TransactionError < StandardError; end
    end
  end
end