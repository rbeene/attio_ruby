# frozen_string_literal: true

require_relative "typed_record"

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
      # @option attributes [String] :stage Deal stage (recommended) - defaults: "Lead", "In Progress", "Won 🎉", "Lost"
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
                { email_address: email }
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
            domains: domains.map { |domain| { domain: domain } }
          }
        end
        
        super(values: values, **opts)
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
      #         {stage: {"$ne": "Won 🎉"}},
      #         {stage: {"$ne": "Lost"}}
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
      
      private
      
      # Build filter for status field (maps to stage)
      def filter_by_status(value)
        { stage: value }
      end
    end

    # Get the deal name
    # @return [String, nil] The deal name
    def name
      self[:name]
    end

    # Get the deal value
    # @return [Numeric, nil] The deal value
    def value
      self[:value]
    end

    # Get the deal stage (API uses "stage" but we provide status for compatibility)
    # @return [String, nil] The deal stage
    def stage
      self[:stage]
    end
    
    # Alias for stage (for compatibility)
    # @return [String, nil] The deal stage
    def status
      self[:stage]
    end

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

    # Check if the deal is open
    # @return [Boolean] True if the deal is open
    def open?
      return false unless stage
      
      stage_title = stage.is_a?(Hash) ? stage.dig("status", "title") : stage
      stage_title && !["won 🎉", "lost"].include?(stage_title.downcase)
    end

    # Check if the deal is won
    # @return [Boolean] True if the deal is won
    def won?
      return false unless stage
      
      stage_title = stage.is_a?(Hash) ? stage.dig("status", "title") : stage
      stage_title && stage_title.downcase.include?("won")
    end

    # Check if the deal is lost
    # @return [Boolean] True if the deal is lost
    def lost?
      return false unless stage
      
      stage_title = stage.is_a?(Hash) ? stage.dig("status", "title") : stage
      stage_title && stage_title.downcase == "lost"
    end

    # # Check if the deal is overdue
    # # @return [Boolean] True if close date has passed and deal is still open
    # def overdue?
    #   return false unless close_date && open?
    #   Date.parse(close_date) < Date.today
    # end
  end

  # Alias for Deal (plural form)
  # @example
  #   Attio::Deals.create(name: "New Deal", value: 10000)
  Deals = Deal
end