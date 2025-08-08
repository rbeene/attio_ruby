# frozen_string_literal: true

require_relative "../util/time_period"

module Attio
  module Concerns
    # Provides time-based filtering methods for any model
    # Include this module to add time filtering capabilities
    module TimeFilterable
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        # Filter records by a time period for a specific date field
        # @param period [Util::TimePeriod] The time period to filter by
        # @param date_field [Symbol] The field to check (default: :created_at)
        # @return [Array] Records within the period
        def in_period(period, date_field: :created_at, **opts)
          all(**opts).select do |record|
            # Try accessor method first, then bracket notation
            date_value = if record.respond_to?(date_field)
              record.send(date_field)
            else
              record[date_field]
            end
            
            if date_value
              parsed_date = date_value.is_a?(String) ? Time.parse(date_value) : date_value
              period.includes?(parsed_date)
            else
              false
            end
          end
        end
        
        # Get records created in the last N days
        # @param days [Integer] Number of days to look back
        # @return [Array] Recently created records
        def recently_created(days = 7, **opts)
          in_period(Util::TimePeriod.last_days(days), date_field: :created_at, **opts)
        end
        
        # Get records updated in the last N days
        # @param days [Integer] Number of days to look back
        # @return [Array] Recently updated records
        def recently_updated(days = 7, **opts)
          in_period(Util::TimePeriod.last_days(days), date_field: :updated_at, **opts)
        end
        
        # Get records created this year
        # @return [Array] Records created in current year
        def created_this_year(**opts)
          in_period(Util::TimePeriod.current_year, date_field: :created_at, **opts)
        end
        
        # Get records created this month
        # @return [Array] Records created in current month
        def created_this_month(**opts)
          in_period(Util::TimePeriod.current_month, date_field: :created_at, **opts)
        end
        
        # Get records created year to date
        # @return [Array] Records created YTD
        def created_year_to_date(**opts)
          in_period(Util::TimePeriod.year_to_date, date_field: :created_at, **opts)
        end
        
        # Get records created in a specific month
        # @param year [Integer] The year
        # @param month [Integer] The month (1-12)
        # @return [Array] Records created in that month
        def created_in_month(year, month, **opts)
          in_period(Util::TimePeriod.month(year, month), date_field: :created_at, **opts)
        end
        
        # Get records created in a specific quarter
        # @param year [Integer] The year
        # @param quarter [Integer] The quarter (1-4)
        # @return [Array] Records created in that quarter
        def created_in_quarter(year, quarter, **opts)
          in_period(Util::TimePeriod.quarter(year, quarter), date_field: :created_at, **opts)
        end
        
        # Get records created in a specific year
        # @param year [Integer] The year
        # @return [Array] Records created in that year
        def created_in_year(year, **opts)
          in_period(Util::TimePeriod.year(year), date_field: :created_at, **opts)
        end
        
        # Get activity metrics for a period
        # @param period [Util::TimePeriod] The time period
        # @return [Hash] Metrics about records in the period
        def activity_metrics(period, **opts)
          created = in_period(period, date_field: :created_at, **opts)
          updated = in_period(period, date_field: :updated_at, **opts)
          
          {
            period: period.label,
            created_count: created.size,
            updated_count: updated.size,
            total_activity: (created + updated).uniq.size
          }
        end
      end
      
      # Instance methods for time-based checks
      
      # Check if this record was created in a specific period
      # @param period [Util::TimePeriod] The time period
      # @return [Boolean] True if created in the period
      def created_in?(period)
        return false unless respond_to?(:created_at) && created_at
        date = created_at.is_a?(String) ? Time.parse(created_at) : created_at
        period.includes?(date)
      end
      
      # Check if this record was updated in a specific period
      # @param period [Util::TimePeriod] The time period
      # @return [Boolean] True if updated in the period
      def updated_in?(period)
        return false unless respond_to?(:updated_at) && updated_at
        date = updated_at.is_a?(String) ? Time.parse(updated_at) : updated_at
        period.includes?(date)
      end
      
      # Get the age of the record in days
      # @return [Integer] Days since creation
      def age_in_days
        return nil unless respond_to?(:created_at) && created_at
        created = created_at.is_a?(String) ? Time.parse(created_at) : created_at
        ((Time.now - created) / (24 * 60 * 60)).round
      end
      
      # Check if record is new (created recently)
      # @param days [Integer] Number of days to consider "new"
      # @return [Boolean] True if created within specified days
      def new?(days = 7)
        age = age_in_days
        age && age <= days
      end
      
      # Check if record is old
      # @param days [Integer] Number of days to consider "old"
      # @return [Boolean] True if created more than specified days ago
      def old?(days = 365)
        age = age_in_days
        age && age > days
      end
    end
  end
end