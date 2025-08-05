# Creating App-Specific TypedRecord Classes

This guide demonstrates how to create custom record classes for your own Attio objects by inheriting from `Attio::TypedRecord`. This allows you to work with your custom objects using the same clean, object-oriented interface that the gem provides for People and Companies.

## Table of Contents
- [Overview](#overview)
- [Basic Structure](#basic-structure)
- [Common Scenario: Deal Records](#common-scenario-deal-records)
- [Naming Conventions](#naming-conventions)
- [Required Methods](#required-methods)
- [Optional Overrides](#optional-overrides)
- [Advanced Examples](#advanced-examples)
- [Best Practices](#best-practices)
- [Integration with Other Records](#integration-with-other-records)

## Overview

The `Attio::TypedRecord` class is designed to be extended for any custom object you've created in your Attio workspace. It provides:

- Automatic object type injection in all API calls
- Simplified CRUD operations
- Consistent interface matching Person and Company classes
- Built-in change tracking and persistence
- Support for custom attribute accessors and business logic

## Basic Structure

Every custom record class must:

1. Inherit from `Attio::TypedRecord`
2. Define the `object_type` (using your object's slug or UUID)
3. Optionally add convenience methods for attributes
4. Optionally override class methods for custom creation/search logic

```ruby
module Attio
  class YourCustomRecord < TypedRecord
    object_type "your_object_slug"  # Required!
    
    # Your custom methods here
  end
end
```

## Common Scenario: Deal Records

Here's a complete implementation of a Deal record class showing all common patterns:

```ruby
# lib/attio/resources/deal.rb
# frozen_string_literal: true

require_relative "typed_record"

module Attio
  # Represents a deal/opportunity record in Attio
  # Provides convenient methods for working with sales pipeline data
  class Deal < TypedRecord
    # REQUIRED: Set the object type to match your Attio object
    # This can be either a slug (like "deals") or a UUID
    object_type "deals"
    
    # ==========================================
    # ATTRIBUTE ACCESSORS (following conventions)
    # ==========================================
    
    # Simple string attribute setter/getter
    # Convention: Use simple assignment for single-value attributes
    def name=(name)
      self[:name] = name
    end
    
    def name
      self[:name]
    end
    
    # Numeric attribute with type conversion
    # Convention: Convert types when it makes sense
    def amount=(value)
      self[:amount] = value.to_f if value
    end
    
    def amount
      self[:amount]
    end
    
    # Select/dropdown attribute
    # Convention: Validate allowed values if known
    VALID_STAGES = ["prospecting", "qualification", "proposal", "negotiation", "closed_won", "closed_lost"].freeze
    
    def stage=(stage)
      if stage && !VALID_STAGES.include?(stage.to_s)
        raise ArgumentError, "Invalid stage: #{stage}. Must be one of: #{VALID_STAGES.join(', ')}"
      end
      self[:stage] = stage
    end
    
    def stage
      self[:stage]
    end
    
    # Date attribute with parsing
    # Convention: Accept multiple date formats for convenience
    def close_date=(date)
      case date
      when String
        self[:close_date] = Date.parse(date).iso8601
      when Date
        self[:close_date] = date.iso8601
      when Time, DateTime
        self[:close_date] = date.to_date.iso8601
      when nil
        self[:close_date] = nil
      else
        raise ArgumentError, "Close date must be a String, Date, Time, or DateTime"
      end
    end
    
    def close_date
      date_str = self[:close_date]
      Date.parse(date_str) if date_str
    end
    
    # Percentage attribute with validation
    # Convention: Validate business rules
    def probability=(value)
      prob = value.to_f
      if prob < 0 || prob > 100
        raise ArgumentError, "Probability must be between 0 and 100"
      end
      self[:probability] = prob
    end
    
    def probability
      self[:probability]
    end
    
    # Reference to another object (similar to Person#company=)
    # Convention: Support both object instances and ID strings
    def account=(account)
      if account.is_a?(Company)
        # Extract ID properly from company instance
        company_id = account.id.is_a?(Hash) ? account.id["record_id"] : account.id
        self[:account] = [{
          target_object: "companies",
          target_record_id: company_id
        }]
      elsif account.is_a?(String)
        self[:account] = [{
          target_object: "companies",
          target_record_id: account
        }]
      elsif account.nil?
        self[:account] = nil
      else
        raise ArgumentError, "Account must be a Company instance or ID string"
      end
    end
    
    # Reference to Person (deal owner)
    def owner=(person)
      if person.is_a?(Person)
        person_id = person.id.is_a?(Hash) ? person.id["record_id"] : person.id
        self[:owner] = [{
          target_object: "people",
          target_record_id: person_id
        }]
      elsif person.is_a?(String)
        self[:owner] = [{
          target_object: "people",
          target_record_id: person
        }]
      elsif person.nil?
        self[:owner] = nil
      else
        raise ArgumentError, "Owner must be a Person instance or ID string"
      end
    end
    
    # Multi-select or array attribute
    # Convention: Provide both array and add/remove methods
    def tags=(tags_array)
      self[:tags] = Array(tags_array)
    end
    
    def tags
      self[:tags] || []
    end
    
    def add_tag(tag)
      current_tags = tags
      self[:tags] = (current_tags << tag).uniq
    end
    
    def remove_tag(tag)
      current_tags = tags
      self[:tags] = current_tags - [tag]
    end
    
    # Text/notes field
    def notes=(notes)
      self[:notes] = notes
    end
    
    def notes
      self[:notes]
    end
    
    # ==========================================
    # COMPUTED PROPERTIES AND BUSINESS LOGIC
    # ==========================================
    
    # Calculate weighted pipeline value
    def weighted_value
      return 0 unless amount && probability
      amount * (probability / 100.0)
    end
    
    # Check if deal is in active pipeline
    def active?
      !closed?
    end
    
    def closed?
      ["closed_won", "closed_lost"].include?(stage)
    end
    
    def won?
      stage == "closed_won"
    end
    
    def lost?
      stage == "closed_lost"
    end
    
    # Days until close date
    def days_to_close
      return nil unless close_date
      (close_date - Date.today).to_i
    end
    
    def overdue?
      return false unless close_date
      close_date < Date.today && !closed?
    end
    
    # ==========================================
    # CLASS METHODS (following Person/Company patterns)
    # ==========================================
    
    class << self
      # Override create to provide a more intuitive interface
      # Convention: List common attributes as named parameters
      def create(name:, amount: nil, stage: "prospecting", owner: nil, 
                 account: nil, close_date: nil, probability: nil, 
                 tags: nil, notes: nil, values: {}, **opts)
        # Build the values hash
        values[:name] = name
        values[:amount] = amount if amount
        values[:stage] = stage
        
        # Handle references
        if owner && !values[:owner]
          owner_ref = if owner.is_a?(Person)
            owner_id = owner.id.is_a?(Hash) ? owner.id["record_id"] : owner.id
            {
              target_object: "people",
              target_record_id: owner_id
            }
          elsif owner.is_a?(String)
            {
              target_object: "people",
              target_record_id: owner
            }
          end
          values[:owner] = [owner_ref] if owner_ref
        end
        
        if account && !values[:account]
          account_ref = if account.is_a?(Company)
            account_id = account.id.is_a?(Hash) ? account.id["record_id"] : account.id
            {
              target_object: "companies",
              target_record_id: account_id
            }
          elsif account.is_a?(String)
            {
              target_object: "companies",
              target_record_id: account
            }
          end
          values[:account] = [account_ref] if account_ref
        end
        
        # Handle dates
        if close_date && !values[:close_date]
          values[:close_date] = case close_date
          when String
            Date.parse(close_date).iso8601
          when Date
            close_date.iso8601
          when Time, DateTime
            close_date.to_date.iso8601
          end
        end
        
        values[:probability] = probability if probability
        values[:tags] = Array(tags) if tags
        values[:notes] = notes if notes
        
        super(values: values, **opts)
      end
      
      # Find deals by stage
      # Convention: Provide find_by_* methods for common queries
      def find_by_stage(stage, **opts)
        list(**opts.merge(
          filter: {
            stage: { "$eq": stage }
          }
        ))
      end
      
      # Find deals by owner
      def find_by_owner(owner, **opts)
        owner_id = case owner
        when Person
          owner.id.is_a?(Hash) ? owner.id["record_id"] : owner.id
        when String
          owner
        else
          raise ArgumentError, "Owner must be a Person instance or ID string"
        end
        
        list(**opts.merge(
          filter: {
            owner: { "$references": owner_id }
          }
        ))
      end
      
      # Find deals by account
      def find_by_account(account, **opts)
        account_id = case account
        when Company
          account.id.is_a?(Hash) ? account.id["record_id"] : account.id
        when String
          account
        else
          raise ArgumentError, "Account must be a Company instance or ID string"
        end
        
        list(**opts.merge(
          filter: {
            account: { "$references": account_id }
          }
        ))
      end
      
      # Find deals closing in the next N days
      def closing_soon(days = 30, **opts)
        today = Date.today
        future_date = today + days
        
        list(**opts.merge(
          filter: {
            "$and": [
              { close_date: { "$gte": today.iso8601 } },
              { close_date: { "$lte": future_date.iso8601 } },
              { stage: { "$nin": ["closed_won", "closed_lost"] } }
            ]
          }
        ))
      end
      
      # Find overdue deals
      def overdue(**opts)
        list(**opts.merge(
          filter: {
            "$and": [
              { close_date: { "$lt": Date.today.iso8601 } },
              { stage: { "$nin": ["closed_won", "closed_lost"] } }
            ]
          }
        ))
      end
      
      # Find high-value deals
      def high_value(threshold = 100000, **opts)
        list(**opts.merge(
          filter: {
            amount: { "$gte": threshold }
          }
        ))
      end
      
      # Search deals by name
      # Convention: Override search to provide meaningful search behavior
      def search(query, **opts)
        list(**opts.merge(
          filter: {
            name: { "$contains": query }
          }
        ))
      end
      
      # Get pipeline summary
      def pipeline_summary(**opts)
        # This would need to aggregate data client-side
        # as Attio doesn't support aggregation queries
        deals = all(**opts)
        
        stages = {}
        VALID_STAGES.each do |stage|
          stage_deals = deals.select { |d| d.stage == stage }
          stages[stage] = {
            count: stage_deals.size,
            total_value: stage_deals.sum(&:amount),
            weighted_value: stage_deals.sum(&:weighted_value)
          }
        end
        
        stages
      end
    end
  end
  
  # Convenience alias (following Person/People pattern)
  Deals = Deal
end
```

## Naming Conventions

Follow these conventions to maintain consistency with the built-in Person and Company classes:

### Class Naming
- Use singular form: `Deal`, not `Deals`
- Add a plural constant alias: `Deals = Deal`
- Use PascalCase for the class name

### Object Type
- Use the plural form from your Attio workspace: `"deals"`, `"tickets"`, `"projects"`
- Can also use the object's UUID if you don't have a slug

### Attribute Methods
- Simple attributes: `name=` / `name`
- Boolean attributes: `active?`, `closed?`, `overdue?`
- Add methods: `add_tag`, `add_comment`, `add_attachment`
- Remove methods: `remove_tag`, `remove_comment`
- Set methods for complex attributes: `set_priority`, `set_status`

### Class Methods
- `create` - Override with named parameters for common attributes
- `find_by_*` - Specific finders like `find_by_email`, `find_by_stage`
- `search` - Override to define how text search works
- Domain-specific queries: `overdue`, `high_priority`, `closing_soon`

## Required Methods

The only truly required element is the `object_type` declaration:

```ruby
class YourRecord < TypedRecord
  object_type "your_object_slug"  # THIS IS REQUIRED!
end
```

Everything else is optional, but you should consider implementing:

1. **Attribute accessors** for all your object's fields
2. **create class method** with named parameters
3. **search class method** with appropriate filters

## Optional Overrides

All these methods can be overridden but have sensible defaults:

### Class Methods (already implemented in TypedRecord)
- `list(**opts)` - Automatically includes object type
- `retrieve(record_id, **opts)` - Automatically includes object type
- `update(record_id, values:, **opts)` - Automatically includes object type
- `delete(record_id, **opts)` - Automatically includes object type
- `find(record_id, **opts)` - Alias for retrieve
- `all(**opts)` - Alias for list
- `find_by(attribute, value, **opts)` - Generic attribute finder

### Instance Methods (inherited from TypedRecord)
- `save(**opts)` - Saves changes if any
- `destroy(**opts)` - Deletes the record
- `persisted?` - Checks if record exists in Attio
- `changed?` - Checks if there are unsaved changes

## Advanced Examples

### Project Management System

```ruby
module Attio
  class Project < TypedRecord
    object_type "projects"
    
    STATUSES = ["planning", "active", "on_hold", "completed", "cancelled"].freeze
    PRIORITIES = ["low", "medium", "high", "critical"].freeze
    
    # Basic attributes
    def name=(name)
      self[:name] = name
    end
    
    def description=(desc)
      self[:description] = desc
    end
    
    def status=(status)
      unless STATUSES.include?(status)
        raise ArgumentError, "Invalid status: #{status}"
      end
      self[:status] = status
    end
    
    def priority=(priority)
      unless PRIORITIES.include?(priority)
        raise ArgumentError, "Invalid priority: #{priority}"
      end
      self[:priority] = priority
    end
    
    # Date handling
    def start_date=(date)
      self[:start_date] = parse_date(date)
    end
    
    def end_date=(date)
      self[:end_date] = parse_date(date)
    end
    
    def start_date
      Date.parse(self[:start_date]) if self[:start_date]
    end
    
    def end_date
      Date.parse(self[:end_date]) if self[:end_date]
    end
    
    # Team members (array of person references)
    def team_members=(people)
      self[:team_members] = people.map do |person|
        person_id = case person
        when Person
          person.id.is_a?(Hash) ? person.id["record_id"] : person.id
        when String
          person
        else
          raise ArgumentError, "Team members must be Person instances or ID strings"
        end
        
        {
          target_object: "people",
          target_record_id: person_id
        }
      end
    end
    
    def add_team_member(person)
      current = self[:team_members] || []
      person_ref = case person
      when Person
        person_id = person.id.is_a?(Hash) ? person.id["record_id"] : person.id
        {
          target_object: "people",
          target_record_id: person_id
        }
      when String
        {
          target_object: "people",
          target_record_id: person
        }
      end
      
      self[:team_members] = current + [person_ref]
    end
    
    # Computed properties
    def duration_days
      return nil unless start_date && end_date
      (end_date - start_date).to_i
    end
    
    def active?
      status == "active"
    end
    
    def completed?
      status == "completed"
    end
    
    def overdue?
      return false unless end_date
      end_date < Date.today && !["completed", "cancelled"].include?(status)
    end
    
    private
    
    def parse_date(date)
      case date
      when String
        Date.parse(date).iso8601
      when Date
        date.iso8601
      when Time, DateTime
        date.to_date.iso8601
      else
        raise ArgumentError, "Date must be a String, Date, Time, or DateTime"
      end
    end
    
    class << self
      def create(name:, status: "planning", priority: "medium", 
                 description: nil, start_date: nil, end_date: nil,
                 team_members: nil, values: {}, **opts)
        values[:name] = name
        values[:status] = status
        values[:priority] = priority
        values[:description] = description if description
        
        if start_date
          values[:start_date] = case start_date
          when String then Date.parse(start_date).iso8601
          when Date then start_date.iso8601
          when Time, DateTime then start_date.to_date.iso8601
          end
        end
        
        if end_date
          values[:end_date] = case end_date
          when String then Date.parse(end_date).iso8601
          when Date then end_date.iso8601
          when Time, DateTime then end_date.to_date.iso8601
          end
        end
        
        if team_members
          values[:team_members] = team_members.map do |person|
            person_id = case person
            when Person
              person.id.is_a?(Hash) ? person.id["record_id"] : person.id
            when String
              person
            end
            
            {
              target_object: "people",
              target_record_id: person_id
            }
          end
        end
        
        super(values: values, **opts)
      end
      
      def active(**opts)
        find_by_status("active", **opts)
      end
      
      def find_by_status(status, **opts)
        list(**opts.merge(
          filter: { status: { "$eq": status } }
        ))
      end
      
      def find_by_priority(priority, **opts)
        list(**opts.merge(
          filter: { priority: { "$eq": priority } }
        ))
      end
      
      def high_priority(**opts)
        list(**opts.merge(
          filter: {
            priority: { "$in": ["high", "critical"] }
          }
        ))
      end
      
      def overdue(**opts)
        list(**opts.merge(
          filter: {
            "$and": [
              { end_date: { "$lt": Date.today.iso8601 } },
              { status: { "$nin": ["completed", "cancelled"] } }
            ]
          }
        ))
      end
      
      def starting_soon(days = 7, **opts)
        today = Date.today
        future_date = today + days
        
        list(**opts.merge(
          filter: {
            "$and": [
              { start_date: { "$gte": today.iso8601 } },
              { start_date: { "$lte": future_date.iso8601 } }
            ]
          }
        ))
      end
    end
  end
  
  Projects = Project
end
```

### Customer Support Tickets

```ruby
module Attio
  class Ticket < TypedRecord
    object_type "support_tickets"
    
    PRIORITIES = ["low", "normal", "high", "urgent"].freeze
    STATUSES = ["new", "open", "pending", "resolved", "closed"].freeze
    CATEGORIES = ["bug", "feature_request", "question", "complaint", "other"].freeze
    
    # Basic attributes
    def subject=(subject)
      self[:subject] = subject
    end
    
    def subject
      self[:subject]
    end
    
    def description=(desc)
      self[:description] = desc
    end
    
    def priority=(priority)
      unless PRIORITIES.include?(priority)
        raise ArgumentError, "Invalid priority: #{priority}"
      end
      self[:priority] = priority
    end
    
    def status=(status)
      unless STATUSES.include?(status)
        raise ArgumentError, "Invalid status: #{status}"
      end
      self[:status] = status
    end
    
    def category=(category)
      unless CATEGORIES.include?(category)
        raise ArgumentError, "Invalid category: #{category}"
      end
      self[:category] = category
    end
    
    # Customer reference
    def customer=(person)
      if person.is_a?(Person)
        person_id = person.id.is_a?(Hash) ? person.id["record_id"] : person.id
        self[:customer] = [{
          target_object: "people",
          target_record_id: person_id
        }]
      elsif person.is_a?(String)
        self[:customer] = [{
          target_object: "people", 
          target_record_id: person
        }]
      else
        raise ArgumentError, "Customer must be a Person instance or ID string"
      end
    end
    
    # Assigned agent
    def assigned_to=(person)
      if person.is_a?(Person)
        person_id = person.id.is_a?(Hash) ? person.id["record_id"] : person.id
        self[:assigned_to] = [{
          target_object: "people",
          target_record_id: person_id
        }]
      elsif person.is_a?(String)
        self[:assigned_to] = [{
          target_object: "people",
          target_record_id: person
        }]
      elsif person.nil?
        self[:assigned_to] = nil
      else
        raise ArgumentError, "Assigned person must be a Person instance or ID string"
      end
    end
    
    # SLA and timing
    def created_at
      Time.parse(self[:created_at]) if self[:created_at]
    end
    
    def resolved_at=(time)
      self[:resolved_at] = time&.iso8601
    end
    
    def resolved_at
      Time.parse(self[:resolved_at]) if self[:resolved_at]
    end
    
    def first_response_at=(time)
      self[:first_response_at] = time&.iso8601
    end
    
    def first_response_at
      Time.parse(self[:first_response_at]) if self[:first_response_at]
    end
    
    # Computed properties
    def open?
      ["new", "open", "pending"].include?(status)
    end
    
    def closed?
      ["resolved", "closed"].include?(status)
    end
    
    def response_time_hours
      return nil unless created_at && first_response_at
      ((first_response_at - created_at) / 3600).round(2)
    end
    
    def resolution_time_hours
      return nil unless created_at && resolved_at
      ((resolved_at - created_at) / 3600).round(2)
    end
    
    def breached_sla?
      return false unless self[:sla_hours]
      return false unless created_at
      
      if open?
        hours_open = (Time.now - created_at) / 3600
        hours_open > self[:sla_hours]
      else
        resolution_time_hours && resolution_time_hours > self[:sla_hours]
      end
    end
    
    # Comments/notes handling
    def add_comment(text, author: nil)
      comments = self[:comments] || []
      comment = {
        text: text,
        created_at: Time.now.iso8601
      }
      
      if author
        author_id = case author
        when Person
          author.id.is_a?(Hash) ? author.id["record_id"] : author.id
        when String
          author
        end
        
        comment[:author] = {
          target_object: "people",
          target_record_id: author_id
        }
      end
      
      self[:comments] = comments + [comment]
    end
    
    class << self
      def create(subject:, description:, customer:, priority: "normal",
                 status: "new", category: "other", assigned_to: nil,
                 sla_hours: nil, values: {}, **opts)
        values[:subject] = subject
        values[:description] = description
        values[:priority] = priority
        values[:status] = status
        values[:category] = category
        values[:sla_hours] = sla_hours if sla_hours
        
        # Handle customer reference
        customer_ref = case customer
        when Person
          customer_id = customer.id.is_a?(Hash) ? customer.id["record_id"] : customer.id
          {
            target_object: "people",
            target_record_id: customer_id
          }
        when String
          {
            target_object: "people",
            target_record_id: customer
          }
        end
        values[:customer] = [customer_ref]
        
        # Handle assigned_to reference
        if assigned_to
          assigned_ref = case assigned_to
          when Person
            assigned_id = assigned_to.id.is_a?(Hash) ? assigned_to.id["record_id"] : assigned_to.id
            {
              target_object: "people",
              target_record_id: assigned_id
            }
          when String
            {
              target_object: "people",
              target_record_id: assigned_to
            }
          end
          values[:assigned_to] = [assigned_ref]
        end
        
        super(values: values, **opts)
      end
      
      def open_tickets(**opts)
        list(**opts.merge(
          filter: {
            status: { "$in": ["new", "open", "pending"] }
          }
        ))
      end
      
      def unassigned(**opts)
        list(**opts.merge(
          filter: {
            assigned_to: { "$exists": false }
          }
        ))
      end
      
      def find_by_customer(customer, **opts)
        customer_id = case customer
        when Person
          customer.id.is_a?(Hash) ? customer.id["record_id"] : customer.id
        when String
          customer
        end
        
        list(**opts.merge(
          filter: {
            customer: { "$references": customer_id }
          }
        ))
      end
      
      def find_by_status(status, **opts)
        list(**opts.merge(
          filter: {
            status: { "$eq": status }
          }
        ))
      end
      
      def high_priority(**opts)
        list(**opts.merge(
          filter: {
            priority: { "$in": ["high", "urgent"] }
          }
        ))
      end
      
      def breached_sla(**opts)
        # This would need to be filtered client-side
        # as Attio doesn't support computed field queries
        tickets = open_tickets(**opts)
        tickets.select(&:breached_sla?)
      end
      
      def search(query, **opts)
        list(**opts.merge(
          filter: {
            "$or": [
              { subject: { "$contains": query } },
              { description: { "$contains": query } }
            ]
          }
        ))
      end
    end
  end
  
  Tickets = Ticket
end
```

### Invoice Records

```ruby
module Attio
  class Invoice < TypedRecord
    object_type "invoices"
    
    STATUSES = ["draft", "sent", "paid", "overdue", "cancelled"].freeze
    
    # Basic attributes
    def invoice_number=(number)
      self[:invoice_number] = number
    end
    
    def invoice_number
      self[:invoice_number]
    end
    
    def amount=(value)
      self[:amount] = value.to_f
    end
    
    def amount
      self[:amount]
    end
    
    def currency=(currency)
      self[:currency] = currency.upcase
    end
    
    def currency
      self[:currency] || "USD"
    end
    
    def status=(status)
      unless STATUSES.include?(status)
        raise ArgumentError, "Invalid status: #{status}"
      end
      self[:status] = status
    end
    
    def status
      self[:status]
    end
    
    # Date handling
    def issue_date=(date)
      self[:issue_date] = parse_date(date)
    end
    
    def issue_date
      Date.parse(self[:issue_date]) if self[:issue_date]
    end
    
    def due_date=(date)
      self[:due_date] = parse_date(date)
    end
    
    def due_date
      Date.parse(self[:due_date]) if self[:due_date]
    end
    
    def paid_date=(date)
      self[:paid_date] = date ? parse_date(date) : nil
    end
    
    def paid_date
      Date.parse(self[:paid_date]) if self[:paid_date]
    end
    
    # Customer reference
    def customer=(company)
      if company.is_a?(Company)
        company_id = company.id.is_a?(Hash) ? company.id["record_id"] : company.id
        self[:customer] = [{
          target_object: "companies",
          target_record_id: company_id
        }]
      elsif company.is_a?(String)
        self[:customer] = [{
          target_object: "companies",
          target_record_id: company
        }]
      else
        raise ArgumentError, "Customer must be a Company instance or ID string"
      end
    end
    
    # Line items (array of hashes)
    def line_items=(items)
      self[:line_items] = items.map do |item|
        {
          description: item[:description],
          quantity: item[:quantity].to_f,
          unit_price: item[:unit_price].to_f,
          total: (item[:quantity].to_f * item[:unit_price].to_f)
        }
      end
    end
    
    def add_line_item(description:, quantity:, unit_price:)
      items = self[:line_items] || []
      items << {
        description: description,
        quantity: quantity.to_f,
        unit_price: unit_price.to_f,
        total: (quantity.to_f * unit_price.to_f)
      }
      self[:line_items] = items
      
      # Recalculate total
      self[:amount] = calculate_total
    end
    
    # Computed properties
    def calculate_total
      return 0 unless self[:line_items]
      
      self[:line_items].sum { |item| item[:total] || 0 }
    end
    
    def days_overdue
      return nil unless due_date && !paid?
      return 0 unless Date.today > due_date
      
      (Date.today - due_date).to_i
    end
    
    def paid?
      status == "paid"
    end
    
    def overdue?
      return false if paid?
      due_date && due_date < Date.today
    end
    
    def mark_as_paid(payment_date = Date.today)
      self.status = "paid"
      self.paid_date = payment_date
    end
    
    private
    
    def parse_date(date)
      case date
      when String
        Date.parse(date).iso8601
      when Date
        date.iso8601
      when Time, DateTime
        date.to_date.iso8601
      else
        raise ArgumentError, "Date must be a String, Date, Time, or DateTime"
      end
    end
    
    class << self
      def create(invoice_number:, customer:, amount:, due_date:,
                 currency: "USD", status: "draft", issue_date: Date.today,
                 line_items: nil, values: {}, **opts)
        values[:invoice_number] = invoice_number
        values[:amount] = amount.to_f
        values[:currency] = currency.upcase
        values[:status] = status
        
        # Handle dates
        values[:issue_date] = case issue_date
        when String then Date.parse(issue_date).iso8601
        when Date then issue_date.iso8601
        when Time, DateTime then issue_date.to_date.iso8601
        end
        
        values[:due_date] = case due_date
        when String then Date.parse(due_date).iso8601
        when Date then due_date.iso8601
        when Time, DateTime then due_date.to_date.iso8601
        end
        
        # Handle customer reference
        customer_ref = case customer
        when Company
          customer_id = customer.id.is_a?(Hash) ? customer.id["record_id"] : customer.id
          {
            target_object: "companies",
            target_record_id: customer_id
          }
        when String
          {
            target_object: "companies",
            target_record_id: customer
          }
        end
        values[:customer] = [customer_ref]
        
        # Handle line items
        if line_items
          values[:line_items] = line_items.map do |item|
            {
              description: item[:description],
              quantity: item[:quantity].to_f,
              unit_price: item[:unit_price].to_f,
              total: (item[:quantity].to_f * item[:unit_price].to_f)
            }
          end
        end
        
        super(values: values, **opts)
      end
      
      def find_by_invoice_number(number, **opts)
        list(**opts.merge(
          filter: {
            invoice_number: { "$eq": number }
          }
        )).first
      end
      
      def find_by_customer(customer, **opts)
        customer_id = case customer
        when Company
          customer.id.is_a?(Hash) ? customer.id["record_id"] : customer.id
        when String
          customer
        end
        
        list(**opts.merge(
          filter: {
            customer: { "$references": customer_id }
          }
        ))
      end
      
      def unpaid(**opts)
        list(**opts.merge(
          filter: {
            status: { "$ne": "paid" }
          }
        ))
      end
      
      def overdue(**opts)
        list(**opts.merge(
          filter: {
            "$and": [
              { status: { "$ne": "paid" } },
              { due_date: { "$lt": Date.today.iso8601 } }
            ]
          }
        ))
      end
      
      def paid_between(start_date, end_date, **opts)
        list(**opts.merge(
          filter: {
            "$and": [
              { status: { "$eq": "paid" } },
              { paid_date: { "$gte": parse_date(start_date) } },
              { paid_date: { "$lte": parse_date(end_date) } }
            ]
          }
        ))
      end
      
      def total_revenue(start_date = nil, end_date = nil, currency: "USD", **opts)
        filters = [
          { status: { "$eq": "paid" } },
          { currency: { "$eq": currency } }
        ]
        
        if start_date
          filters << { paid_date: { "$gte": parse_date(start_date) } }
        end
        
        if end_date
          filters << { paid_date: { "$lte": parse_date(end_date) } }
        end
        
        invoices = list(**opts.merge(
          filter: { "$and": filters }
        ))
        
        invoices.sum(&:amount)
      end
      
      private
      
      def parse_date(date)
        case date
        when String then Date.parse(date).iso8601
        when Date then date.iso8601
        when Time, DateTime then date.to_date.iso8601
        else date
        end
      end
    end
  end
  
  Invoices = Invoice
end
```

## Best Practices

### 1. Attribute Handling

Always provide both setter and getter methods for attributes:

```ruby
# Good
def status=(value)
  self[:status] = value
end

def status
  self[:status]
end

# Better - with validation
def status=(value)
  unless VALID_STATUSES.include?(value)
    raise ArgumentError, "Invalid status: #{value}"
  end
  self[:status] = value
end
```

### 2. Date Handling

Be flexible with date inputs:

```ruby
def due_date=(date)
  self[:due_date] = case date
  when String
    Date.parse(date).iso8601
  when Date
    date.iso8601
  when Time, DateTime
    date.to_date.iso8601
  when nil
    nil
  else
    raise ArgumentError, "Date must be a String, Date, Time, or DateTime"
  end
end

def due_date
  Date.parse(self[:due_date]) if self[:due_date]
end
```

### 3. Reference Handling

Support both object instances and ID strings:

```ruby
def owner=(person)
  if person.is_a?(Person)
    person_id = person.id.is_a?(Hash) ? person.id["record_id"] : person.id
    self[:owner] = [{
      target_object: "people",
      target_record_id: person_id
    }]
  elsif person.is_a?(String)
    self[:owner] = [{
      target_object: "people",
      target_record_id: person
    }]
  elsif person.nil?
    self[:owner] = nil
  else
    raise ArgumentError, "Owner must be a Person instance or ID string"
  end
end
```

### 4. Array Attributes

Provide both bulk and individual manipulation methods:

```ruby
def tags=(tags_array)
  self[:tags] = Array(tags_array)
end

def tags
  self[:tags] || []
end

def add_tag(tag)
  self[:tags] = (tags || []) << tag
end

def remove_tag(tag)
  self[:tags] = tags - [tag]
end

def has_tag?(tag)
  tags.include?(tag)
end
```

### 5. Search and Filtering

Use Attio's filter syntax properly:

```ruby
# Text search
def self.search(query, **opts)
  list(**opts.merge(
    filter: {
      "$or": [
        { name: { "$contains": query } },
        { description: { "$contains": query } }
      ]
    }
  ))
end

# Reference filtering
def self.find_by_owner(owner, **opts)
  owner_id = extract_id(owner)
  list(**opts.merge(
    filter: {
      owner: { "$references": owner_id }
    }
  ))
end

# Date range filtering
def self.created_between(start_date, end_date, **opts)
  list(**opts.merge(
    filter: {
      "$and": [
        { created_at: { "$gte": start_date.iso8601 } },
        { created_at: { "$lte": end_date.iso8601 } }
      ]
    }
  ))
end
```

### 6. Error Handling

Always validate inputs and provide clear error messages:

```ruby
def priority=(value)
  unless VALID_PRIORITIES.include?(value)
    raise ArgumentError, "Invalid priority: #{value}. Must be one of: #{VALID_PRIORITIES.join(', ')}"
  end
  self[:priority] = value
end
```

### 7. Computed Properties

Add methods that calculate values based on attributes:

```ruby
def days_until_due
  return nil unless due_date
  (due_date - Date.today).to_i
end

def completion_percentage
  return 0 unless total_tasks && completed_tasks
  ((completed_tasks.to_f / total_tasks) * 100).round
end
```

## Integration with Other Records

Your custom records can reference and interact with other records:

```ruby
class Deal < TypedRecord
  object_type "deals"
  
  # Reference to a Company
  def account=(company)
    # ... handle Company reference
  end
  
  # Reference to a Person
  def owner=(person)
    # ... handle Person reference
  end
  
  # Get all activities related to this deal
  def activities(**opts)
    Activity.find_by_deal(self, **opts)
  end
  
  # Create a related activity
  def create_activity(type:, description:, **opts)
    Activity.create(
      deal: self,
      type: type,
      description: description,
      **opts
    )
  end
end

class Activity < TypedRecord
  object_type "activities"
  
  # Reference back to deal
  def deal=(deal)
    if deal.is_a?(Deal)
      deal_id = deal.id.is_a?(Hash) ? deal.id["record_id"] : deal.id
      self[:deal] = [{
        target_object: "deals",
        target_record_id: deal_id
      }]
    elsif deal.is_a?(String)
      self[:deal] = [{
        target_object: "deals",
        target_record_id: deal
      }]
    end
  end
  
  class << self
    def find_by_deal(deal, **opts)
      deal_id = case deal
      when Deal
        deal.id.is_a?(Hash) ? deal.id["record_id"] : deal.id
      when String
        deal
      end
      
      list(**opts.merge(
        filter: {
          deal: { "$references": deal_id }
        }
      ))
    end
  end
end
```

## Testing Your Custom Records

Here's an example of how to test your custom record class:

```ruby
# spec/attio/resources/deal_spec.rb
require "spec_helper"

RSpec.describe Attio::Deal do
  describe "object_type" do
    it "returns the correct object type" do
      expect(described_class.object_type).to eq("deals")
    end
  end
  
  describe ".create" do
    it "creates a deal with all attributes" do
      deal = described_class.create(
        name: "Big Sale",
        amount: 100000,
        stage: "negotiation",
        close_date: "2024-12-31"
      )
      
      expect(deal.name).to eq("Big Sale")
      expect(deal.amount).to eq(100000.0)
      expect(deal.stage).to eq("negotiation")
      expect(deal.close_date).to eq(Date.parse("2024-12-31"))
    end
    
    it "validates stage values" do
      expect {
        described_class.new.stage = "invalid_stage"
      }.to raise_error(ArgumentError, /Invalid stage/)
    end
  end
  
  describe "#weighted_value" do
    it "calculates weighted pipeline value" do
      deal = described_class.new
      deal.amount = 100000
      deal.probability = 75
      
      expect(deal.weighted_value).to eq(75000.0)
    end
  end
  
  describe ".closing_soon" do
    it "finds deals closing in the next N days" do
      VCR.use_cassette("deals_closing_soon") do
        deals = described_class.closing_soon(30)
        
        expect(deals).to all(be_a(Attio::Deal))
        expect(deals).to all(satisfy { |d| 
          d.close_date && d.close_date <= Date.today + 30
        })
      end
    end
  end
end
```

## Summary

Creating custom TypedRecord classes allows you to:

1. Work with your custom Attio objects using clean Ruby syntax
2. Add business logic and computed properties
3. Validate data before sending to the API
4. Create intuitive query methods
5. Handle complex relationships between objects
6. Maintain consistency with the gem's built-in classes

The key is to follow the patterns established by the Person and Company classes while adapting them to your specific business needs.