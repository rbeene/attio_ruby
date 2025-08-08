# frozen_string_literal: true

require "date"

module Attio
  module Util
    # Utility class for time period calculations
    class TimePeriod
      attr_reader :start_date, :end_date

      def initialize(start_date, end_date)
        @start_date = parse_date(start_date)
        @end_date = parse_date(end_date)
      end

      private

      def parse_date(date)
        case date
        when Date
          date
        when String
          Date.parse(date)
        else
          date.to_date
        end
      end

      public

      # Named constructors for common periods

      # Current year to date
      def self.year_to_date
        today = Date.today
        new(Date.new(today.year, 1, 1), today)
      end

      # Current month to date
      def self.month_to_date
        today = Date.today
        new(Date.new(today.year, today.month, 1), today)
      end

      # Current quarter to date
      def self.quarter_to_date
        today = Date.today
        quarter = (today.month - 1) / 3 + 1
        quarter_start = Date.new(today.year, (quarter - 1) * 3 + 1, 1)
        new(quarter_start, today)
      end

      # Specific quarter
      def self.quarter(year, quarter_num)
        raise ArgumentError, "Quarter must be between 1 and 4" unless (1..4).cover?(quarter_num)
        quarter_start = Date.new(year, (quarter_num - 1) * 3 + 1, 1)
        quarter_end = (quarter_start >> 3) - 1
        new(quarter_start, quarter_end)
      end

      # Current quarter (full quarter, not QTD)
      def self.current_quarter
        today = Date.today
        quarter(today.year, (today.month - 1) / 3 + 1)
      end

      # Previous quarter
      def self.previous_quarter
        today = Date.today
        current_q = (today.month - 1) / 3 + 1
        if current_q == 1
          quarter(today.year - 1, 4)
        else
          quarter(today.year, current_q - 1)
        end
      end

      # Specific month
      def self.month(year, month_num)
        raise ArgumentError, "Month must be between 1 and 12" unless (1..12).cover?(month_num)
        month_start = Date.new(year, month_num, 1)
        month_end = (month_start >> 1) - 1
        new(month_start, month_end)
      end

      # Current month (full month, not MTD)
      def self.current_month
        today = Date.today
        month(today.year, today.month)
      end

      # Previous month
      def self.previous_month
        today = Date.today
        if today.month == 1
          month(today.year - 1, 12)
        else
          month(today.year, today.month - 1)
        end
      end

      # Specific year
      def self.year(year_num)
        new(Date.new(year_num, 1, 1), Date.new(year_num, 12, 31))
      end

      # Current year (full year, not YTD)
      def self.current_year
        year(Date.today.year)
      end

      # Previous year
      def self.previous_year
        year(Date.today.year - 1)
      end

      # Last N days (including today)
      def self.last_days(num_days)
        today = Date.today
        new(today - num_days + 1, today)
      end

      # Last 7 days
      def self.last_week
        last_days(7)
      end

      # Last 30 days
      def self.last_30_days
        last_days(30)
      end

      # Last 90 days
      def self.last_90_days
        last_days(90)
      end

      # Last 365 days
      def self.last_year_rolling
        last_days(365)
      end

      # Custom range
      def self.between(start_date, end_date)
        new(start_date, end_date)
      end

      # Instance methods

      # Check if a date falls within this period
      def includes?(date)
        date = date.to_date
        date.between?(@start_date, @end_date)
      end

      # Get the date range
      def to_range
        @start_date..@end_date
      end

      # Number of days in the period
      def days
        (@end_date - @start_date).to_i + 1
      end

      # String representation
      def to_s
        if @start_date == @end_date
          @start_date.to_s
        else
          "#{@start_date} to #{@end_date}"
        end
      end

      # Human-readable label
      def label
        today = Date.today

        # Check for common patterns
        if @start_date == Date.new(today.year, 1, 1) && @end_date == today
          "Year to Date"
        elsif @start_date == Date.new(today.year, today.month, 1) && @end_date == today
          "Month to Date"
        elsif @start_date == Date.new(today.year, 1, 1) && @end_date == Date.new(today.year, 12, 31)
          today.year.to_s
        elsif @start_date.day == 1 && @end_date == (@start_date >> 1) - 1
          @start_date.strftime("%B %Y")
        elsif days == 7 && @end_date == today
          "Last 7 Days"
        elsif days == 30 && @end_date == today
          "Last 30 Days"
        elsif days == 90 && @end_date == today
          "Last 90 Days"
        else
          # Check for quarters
          quarter = detect_quarter
          return quarter if quarter

          to_s
        end
      end

      private

      def detect_quarter
        # Check if this is a complete quarter
        [1, 2, 3, 4].each do |q|
          quarter_start = Date.new(@start_date.year, (q - 1) * 3 + 1, 1)
          quarter_end = (quarter_start >> 3) - 1

          if @start_date == quarter_start && @end_date == quarter_end
            return "Q#{q} #{@start_date.year}"
          end
        end
        nil
      end
    end
  end
end
