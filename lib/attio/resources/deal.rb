# frozen_string_literal: true

require_relative "typed_record"
require_relative "../util/time_period"
require_relative "../util/currency_formatter"

module Attio
  # Represents a Deal record in Attio
  #
  # @example Create a deal
  #   deal = Attio::Deal.create(
  #     name: "Enterprise Deal",
  #     value: 50000,
  #     stage: "In Progress"
  #   )
  #
  # @example Find deals by status
  #   open_deals = Attio::Deal.find_by(status: "open")
  #   won_deals = Attio::Deal.find_by(status: "won")
  #
  # @example Find high-value deals
  #   big_deals = Attio::Deal.find_by_value_range(min: 100000)
  #
  # @example Update deal status
  #   deal.update_status("won")
  #
  class Deal < TypedRecord
    object_type "deals"

    class << self
      # Create a deal with a simplified interface
      # @param attributes [Hash] Deal attributes
      # @option attributes [String] :name Deal name (recommended)
      # @option attributes [Numeric] :value Deal value (recommended)
      # @option attributes [String] :stage Deal stage (recommended) - configurable via Attio.configuration
      # @option attributes [String] :status Deal status (alias for stage)
      # @option attributes [String] :owner Owner email or workspace member (recommended)
      # @option attributes [Array<String>] :associated_people Email addresses of associated people
      # @option attributes [Array<String>] :associated_company Domains of associated companies
      # @option attributes [Hash] :values Raw values hash (for advanced use)
      def create(name:, value: nil, stage: nil, status: nil, owner: nil,
        associated_people: nil, associated_company: nil, values: {}, **opts)
        # Name is required and simple
        values[:name] = name if name && !values[:name]

        # Add optional fields
        values[:value] = value if value && !values[:value]

        # Handle stage vs status - API uses "stage" but we support both
        if (stage || status) && !values[:stage]
          values[:stage] = stage || status
        end

        # Handle owner - can be email address or workspace member reference
        if owner && !values[:owner]
          values[:owner] = owner
        end

        # Handle associated people - convert email array to proper format
        if associated_people && !values[:associated_people]
          values[:associated_people] = associated_people.map do |email|
            {
              target_object: "people",
              email_addresses: [
                {email_address: email}
              ]
            }
          end
        end

        # Handle associated company - convert domain array to proper format
        if associated_company && !values[:associated_company]
          # associated_company can be array of domains or single domain
          domains = associated_company.is_a?(Array) ? associated_company : [associated_company]
          values[:associated_company] = {
            target_object: "companies",
            domains: domains.map { |domain| {domain: domain} }
          }
        end

        super(values: values, **opts)
      end

      # Find deals by stage names
      # @param stage_names [Array<String>] Array of stage names to filter by
      # @return [Attio::ListObject] List of matching deals
      def in_stage(stage_names:, **opts)
        # If only one stage, use simple equality
        filter = if stage_names.length == 1
          {stage: stage_names.first}
        else
          # Multiple stages need $or operator
          {
            "$or": stage_names.map { |stage| {stage: stage} }
          }
        end

        list(**opts.merge(params: {filter: filter}))
      end

      # Find won deals using configured statuses
      # @return [Attio::ListObject] List of won deals
      def won(**opts)
        in_stage(stage_names: Attio.configuration.won_statuses, **opts)
      end

      # Find lost deals using configured statuses
      # @return [Attio::ListObject] List of lost deals
      def lost(**opts)
        in_stage(stage_names: Attio.configuration.lost_statuses, **opts)
      end

      # Find open deals (Lead + In Progress) using configured statuses
      # @return [Attio::ListObject] List of open deals
      def open_deals(**opts)
        all_open_statuses = Attio.configuration.open_statuses + Attio.configuration.in_progress_statuses
        in_stage(stage_names: all_open_statuses, **opts)
      end

      # Find deals within a value range
      # @param min [Numeric] Minimum value (optional)
      # @param max [Numeric] Maximum value (optional)
      # @return [Attio::ListObject] List of matching deals
      def find_by_value_range(min: nil, max: nil, **opts)
        filters = []
        filters << {value: {"$gte": min}} if min
        filters << {value: {"$lte": max}} if max

        filter = if filters.length == 1
          filters.first
        elsif filters.length > 1
          {"$and": filters}
        else
          {}
        end

        list(**opts.merge(params: {filter: filter}))
      end

      # # Find deals closing soon (requires close_date attribute)
      # # @param days [Integer] Number of days from today
      # # @return [Attio::ListObject] List of deals closing soon
      # def closing_soon(days: 30, **opts)
      #   today = Date.today
      #   end_date = today + days
      #
      #   list(**opts.merge(params: {
      #     filter: {
      #       "$and": [
      #         {close_date: {"$gte": today.iso8601}},
      #         {close_date: {"$lte": end_date.iso8601}},
      #         # Exclude won and lost statuses
      #         {"$not": {stage: {"$in": Attio.configuration.won_statuses}}},
      #         {"$not": {stage: {"$in": Attio.configuration.lost_statuses}}}
      #       ]
      #     }
      #   }))
      # end

      # Find deals by owner
      # @param owner_id [String] The workspace member ID
      # @return [Attio::ListObject] List of deals owned by the member
      def find_by_owner(owner_id, **opts)
        list(**opts.merge(params: {
          filter: {
            owner: {
              target_object: "workspace_members",
              target_record_id: owner_id
            }
          }
        }))
      end

      # Get deals that closed in a specific time period
      # @param period [Util::TimePeriod] The time period
      # @return [Array<Attio::Deal>] List of deals closed in the period
      def closed_in_period(period, **opts)
        all(**opts).select do |deal|
          closed_date = deal.closed_at
          closed_date && period.includes?(closed_date)
        end
      end

      # Get deals that closed in a specific quarter
      # @param year [Integer] The year
      # @param quarter [Integer] The quarter (1-4)
      # @return [Array<Attio::Deal>] List of deals closed in the quarter
      def closed_in_quarter(year, quarter, **opts)
        period = Util::TimePeriod.quarter(year, quarter)
        closed_in_period(period, **opts)
      end

      # Get metrics for any time period
      # @param period [Util::TimePeriod] The time period
      # @return [Hash] Metrics for the period
      def metrics_for_period(period, **opts)
        # Build date filter for stage.active_from
        # Note: We need to add a day to end_date to include all of that day
        # since stage.active_from includes time
        date_filter = {
          "stage" => {
            "active_from" => {
              "$gte" => period.start_date.strftime("%Y-%m-%d"),
              "$lte" => (period.end_date + 1).strftime("%Y-%m-%d")
            }
          }
        }

        # Fetch won deals closed in the period
        won_statuses = ::Attio.configuration.won_statuses
        won_conditions = won_statuses.map { |status| {"stage" => status} }
        won_filter = {
          "$and" => [
            won_conditions.size > 1 ? {"$or" => won_conditions} : won_conditions.first,
            date_filter
          ].compact
        }
        won_response = list(**opts.merge(params: {filter: won_filter}))

        # Fetch lost deals closed in the period
        lost_statuses = ::Attio.configuration.lost_statuses
        lost_conditions = lost_statuses.map { |status| {"stage" => status} }
        lost_filter = {
          "$and" => [
            lost_conditions.size > 1 ? {"$or" => lost_conditions} : lost_conditions.first,
            date_filter
          ].compact
        }
        lost_response = list(**opts.merge(params: {filter: lost_filter}))

        won_deals = won_response.data
        lost_deals = lost_response.data
        total_closed = won_deals.size + lost_deals.size

        {
          period: period.label,
          won_count: won_deals.size,
          won_amount: won_deals.sum(&:amount),
          lost_count: lost_deals.size,
          lost_amount: lost_deals.sum(&:amount),
          total_closed: total_closed,
          win_rate: (total_closed > 0) ? (won_deals.size.to_f / total_closed * 100).round(2) : 0.0
        }
      end

      # Get current quarter metrics
      # @return [Hash] Metrics for the current quarter
      def current_quarter_metrics(**opts)
        metrics_for_period(Util::TimePeriod.current_quarter, **opts)
      end

      # Get year-to-date metrics
      # @return [Hash] Metrics for year to date
      def year_to_date_metrics(**opts)
        metrics_for_period(Util::TimePeriod.year_to_date, **opts)
      end

      # Get month-to-date metrics
      # @return [Hash] Metrics for month to date
      def month_to_date_metrics(**opts)
        metrics_for_period(Util::TimePeriod.month_to_date, **opts)
      end

      # Get last 30 days metrics
      # @return [Hash] Metrics for last 30 days
      def last_30_days_metrics(**opts)
        metrics_for_period(Util::TimePeriod.last_30_days, **opts)
      end

      # Get high-value deals above a threshold
      # @param threshold [Numeric] The minimum value threshold (defaults to 50,000)
      # @return [Array<Attio::Deal>] List of high-value deals
      def high_value(threshold = 50_000, **opts)
        all(**opts).select { |deal| deal.amount > threshold }
      end

      # Get deals without owners
      # @return [Array<Attio::Deal>] List of unassigned deals
      def unassigned(**opts)
        all(**opts).select { |deal| deal.owner.nil? }
      end

      # Get recently created deals
      # @param days [Integer] Number of days to look back (defaults to 7)
      # @return [Array<Attio::Deal>] List of recently created deals
      def recently_created(days = 7, **opts)
        created_in_period(Util::TimePeriod.last_days(days), **opts)
      end

      # Get deals created in a specific period
      # @param period [Util::TimePeriod] The time period
      # @return [Array<Attio::Deal>] List of deals created in the period
      def created_in_period(period, **opts)
        all(**opts).select do |deal|
          created_at = deal.created_at
          created_at && period.includes?(created_at)
        end
      end

      private

      # Build filter for status field (maps to stage)
      def filter_by_status(value)
        {stage: value}
      end
    end

    # Get the deal name
    # @return [String, nil] The deal name
    def name
      self[:name]
    end

    # Get the monetary amount from the deal value
    # @return [Float] The deal amount (0.0 if not set)
    def amount
      return 0.0 unless self[:value].is_a?(Hash)
      (self[:value]["currency_value"] || 0).to_f
    end

    # Get the currency code
    # @return [String] The currency code (defaults to "USD")
    def currency
      return "USD" unless self[:value].is_a?(Hash)
      self[:value]["currency_code"] || "USD"
    end

    # Get formatted amount for display
    # @return [String] The formatted currency amount
    def formatted_amount
      Util::CurrencyFormatter.format(amount, currency)
    end

    # Get the raw deal value (for backward compatibility)
    # @deprecated Use {#amount} for monetary values or {#raw_value} for raw API response
    # @return [Object] The raw value from the API
    def value
      warn "[DEPRECATION] `value` is deprecated. Use `amount` for monetary values or `raw_value` for the raw API response." unless ENV["ATTIO_SUPPRESS_DEPRECATION"]
      amount
    end

    # Get the raw value data from the API
    # @return [Object] The raw value data
    def raw_value
      self[:value]
    end

    # Get the normalized deal stage/status
    # @return [String, nil] The deal stage title
    def stage
      stage_data = self[:stage]
      return nil unless stage_data.is_a?(Hash)

      # Attio always returns stage as a hash with nested status.title
      stage_data.dig("status", "title")
    end

    # Alias for stage (for compatibility)
    # @return [String, nil] The deal stage
    alias_method :status, :stage

    # # Get the close date (if attribute exists)
    # # @return [String, nil] The close date
    # def close_date
    #   self[:close_date]
    # end

    # # Get the probability (if attribute exists)
    # # @return [Numeric, nil] The win probability
    # def probability
    #   self[:probability]
    # end

    # Get the owner reference
    # @return [Hash, nil] The owner reference
    def owner
      self[:owner]
    end

    # Get the company reference
    # @return [Hash, nil] The company reference
    def company
      self[:company]
    end

    # Update the deal stage
    # @param new_stage [String] The new stage
    # @return [Attio::Deal] The updated deal
    def update_stage(new_stage, **opts)
      self.class.update(id, values: {stage: new_stage}, **opts)
    end

    # Alias for update_stage (for compatibility)
    # @param new_status [String] The new status/stage
    # @return [Attio::Deal] The updated deal
    def update_status(new_status, **opts)
      update_stage(new_status, **opts)
    end

    # # Update the deal probability (if attribute exists)
    # # @param new_probability [Numeric] The new probability (0-100)
    # # @return [Attio::Deal] The updated deal
    # def update_probability(new_probability, **opts)
    #   self.class.update(id, values: {probability: new_probability}, **opts)
    # end

    # Update the deal value
    # @param new_value [Numeric] The new value
    # @return [Attio::Deal] The updated deal
    def update_value(new_value, **opts)
      self.class.update(id, values: {value: new_value}, **opts)
    end

    # Get the associated company record
    # @return [Attio::Company, nil] The company record if associated
    def company_record(**opts)
      return nil unless company

      company_id = company.is_a?(Hash) ? company["target_record_id"] : company
      Company.retrieve(company_id, **opts) if company_id
    end

    # Get the owner workspace member record
    # @return [Attio::WorkspaceMember, nil] The owner record if assigned
    def owner_record(**opts)
      return nil unless owner

      owner_id = if owner.is_a?(Hash)
        owner["referenced_actor_id"] || owner["target_record_id"]
      else
        owner
      end
      WorkspaceMember.retrieve(owner_id, **opts) if owner_id
    end

    # # Calculate expected revenue (value * probability / 100)
    # # @return [Numeric, nil] The expected revenue
    # def expected_revenue
    #   return nil unless value && probability
    #   (value * probability / 100.0).round(2)
    # end

    # Get the current status title (delegates to stage for simplicity)
    # @return [String, nil] The current status title
    def current_status
      stage
    end

    # Get the timestamp when the status changed
    # @return [Time, nil] The timestamp when status changed
    def status_changed_at
      return nil unless self[:stage].is_a?(Hash)

      # Attio returns active_from at the top level of the stage hash
      timestamp = self[:stage]["active_from"]
      timestamp ? Time.parse(timestamp) : nil
    end

    # Check if the deal is open
    # @return [Boolean] True if the deal is open
    def open?
      return false unless current_status

      all_open_statuses = Attio.configuration.open_statuses + Attio.configuration.in_progress_statuses
      all_open_statuses.include?(current_status)
    end

    # Check if the deal is won
    # @return [Boolean] True if the deal is won
    def won?
      return false unless current_status

      Attio.configuration.won_statuses.include?(current_status)
    end

    # Check if the deal is lost
    # @return [Boolean] True if the deal is lost
    def lost?
      return false unless current_status

      Attio.configuration.lost_statuses.include?(current_status)
    end

    # Get the timestamp when the deal was won
    # @return [Time, nil] The timestamp when deal was won, or nil if not won
    def won_at
      return nil unless won?
      status_changed_at
    end

    # Get the timestamp when the deal was closed (won or lost)
    # @return [Time, nil] The timestamp when deal was closed, or nil if still open
    def closed_at
      return nil unless won? || lost?
      status_changed_at
    end

    # # Check if the deal is overdue
    # # @return [Boolean] True if close date has passed and deal is still open
    # def overdue?
    #   return false unless close_date && open?
    #   Date.parse(close_date) < Date.today
    # end

    # Check if this is an enterprise deal
    # @return [Boolean] True if amount > 100,000
    def enterprise?
      amount > 100_000
    end

    # Check if this is a mid-market deal
    # @return [Boolean] True if amount is between 10,000 and 100,000
    def mid_market?
      amount.between?(10_000, 100_000)
    end

    # Check if this is a small deal
    # @return [Boolean] True if amount < 10,000
    def small?
      amount < 10_000
    end

    # Get the number of days the deal has been in current stage
    # @return [Integer] Number of days in current stage
    def days_in_stage
      return 0 unless status_changed_at
      ((Time.now - status_changed_at) / (24 * 60 * 60)).round
    end

    # Check if the deal is stale (no activity for specified days)
    # @param days [Integer] Number of days to consider stale (defaults to 30)
    # @return [Boolean] True if deal is open and hasn't changed in specified days
    def stale?(days = 30)
      return false if closed?
      days_in_stage > days
    end

    # Check if the deal is closed (won or lost)
    # @return [Boolean] True if deal is won or lost
    def closed?
      won? || lost?
    end

    # Get a simple summary of the deal
    # @return [String] Summary string with name, amount, and stage
    def summary
      "#{name || "Unnamed Deal"}: #{formatted_amount} (#{stage || "No Stage"})"
    end

    # Convert to string for display
    # @return [String] The deal summary
    def to_s
      summary
    end

    # Get deal size category
    # @return [Symbol] :enterprise, :mid_market, or :small
    def size_category
      if enterprise?
        :enterprise
      elsif mid_market?
        :mid_market
      else
        :small
      end
    end

    # Check if deal needs attention (stale and not closed)
    # @param stale_days [Integer] Days to consider stale
    # @return [Boolean] True if deal needs attention
    def needs_attention?(stale_days = 30)
      !closed? && stale?(stale_days)
    end

    # Get deal velocity (amount per day if closed)
    # @return [Float, nil] Amount per day or nil if not closed
    def velocity
      return nil unless closed? && closed_at && created_at

      days_to_close = ((closed_at - created_at) / (24 * 60 * 60)).round
      (days_to_close > 0) ? (amount / days_to_close).round(2) : amount
    end
  end

  # Alias for Deal (plural form)
  # @example
  #   Attio::Deals.create(name: "New Deal", value: 10000)
  Deals = Deal
end
