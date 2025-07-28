# frozen_string_literal: true

require_relative "typed_record"

module Attio
  # Represents a company record in Attio
  # Provides convenient methods for working with companies and their attributes
  class Company < TypedRecord
    object_type "companies"

    # Set the company name (much simpler than person names!)
    # @param name [String] The company name
    def name=(name)
      self[:name] = name
    end

    # Get the company name
    # @return [String, nil] The company name or nil if not set
    def name
      self[:name]
    end

    # Add a domain
    # @param domain [String] The domain to add (e.g., "example.com")
    def add_domain(domain)
      domains = self[:domains] || []
      # Ensure it's an array
      domains = [domains] unless domains.is_a?(Array)

      # Normalize domain (remove protocol if present)
      domain = domain.sub(/^https?:\/\//, "")

      # Add the domain if it's not already present
      domains << domain unless domains.any? { |d|
        d.is_a?(Hash) ? (d["domain"] == domain || d[:domain] == domain) : d == domain
      }
      self[:domains] = domains
    end

    # Get the primary domain
    # @return [String, nil] The primary domain or nil if not set
    def domain
      domains = self[:domains]
      return nil unless domains

      if domains.is_a?(Array) && !domains.empty?
        domain = domains.first
        if domain.is_a?(Hash)
          domain["domain"] || domain[:domain]
        else
          domain.to_s
        end
      elsif domains.is_a?(Hash)
        domains["domain"] || domains[:domain]
      else
        domains.to_s
      end
    end

    # Get all domains
    # @return [Array<String>] Array of domain strings
    def domains_list
      domains = self[:domains]
      return [] unless domains

      if domains.is_a?(Array)
        domains.filter_map do |d|
          if d.is_a?(Hash)
            d["domain"] || d[:domain]
          else
            d.to_s
          end
        end
      else
        [domain].compact
      end
    end

    # Set the company description
    # @param description [String] The company description
    def description=(desc)
      self[:description] = desc
    end

    # Set the employee count
    # @param count [Integer, String] The employee count or range (e.g., "10-50")
    def employee_count=(count)
      self[:employee_count] = count.to_s
    end

    # Add a team member (person) to this company
    # @param person [Person, String] A Person instance or person ID
    def add_team_member(person)
      # This would typically be done from the Person side
      # but we can provide a convenience method
      if person.is_a?(Person)
        person.company = self
        person.save
      elsif person.is_a?(String)
        # If it's an ID, we need to fetch and update the person
        retrieved_person = Person.retrieve(person)
        retrieved_person.company = self
        retrieved_person.save
      else
        raise ArgumentError, "Team member must be a Person instance or ID string"
      end
    end

    # Get all people associated with this company
    # @return [Attio::ListObject] List of people
    def team_members(**opts)
      company_id = id.is_a?(Hash) ? id["record_id"] : id
      Person.list(**opts.merge(params: {
        filter: {
          company: {"$references": company_id}
        }
      }))
    end

    class << self
      # Create a company with a simplified interface
      # @param attributes [Hash] Company attributes
      # @option attributes [String] :name Company name (required)
      # @option attributes [String, Array<String>] :domain Domain(s)
      # @option attributes [String] :description Company description
      # @option attributes [String, Integer] :employee_count Employee count
      # @option attributes [Hash] :values Raw values hash (for advanced use)
      def create(name:, domain: nil, domains: nil, description: nil,
        employee_count: nil, values: {}, **opts)
        # Name is required and simple for companies
        values[:name] = name

        # Handle domains
        if domain || domains
          domain_list = []
          domain_list << domain if domain
          domain_list += Array(domains) if domains
          values[:domains] = domain_list.uniq unless domain_list.empty?
        end

        values[:description] = description if description
        values[:employee_count] = employee_count.to_s if employee_count

        super(values: values, **opts)
      end

      # Find a company by domain
      # @param domain [String] Domain to search for
      def find_by_domain(domain, **opts)
        # Normalize domain
        domain = domain.sub(/^https?:\/\//, "")

        list(**opts.merge(params: {
          filter: {
            domains: {"$contains": domain}
          }
        })).first
      end

      # Find companies by name
      # @param name [String] Name to search for
      def find_by_name(name, **opts)
        results = search(name, **opts)
        results.first
      end

      # Find companies by employee count range
      # @param min [Integer] Minimum employee count
      # @param max [Integer] Maximum employee count (optional)
      def find_by_size(min, max = nil, **opts)
        filter = if max
          {
            employee_count: {
              "$gte": min.to_s,
              "$lte": max.to_s
            }
          }
        else
          {
            employee_count: {"$gte": min.to_s}
          }
        end

        list(**opts.merge(params: {filter: filter}))
      end
    end
  end

  # Convenience alias
  Companies = Company
end
