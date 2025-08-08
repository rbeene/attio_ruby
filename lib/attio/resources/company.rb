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

      # Check if domain already exists
      exists = domains.any? { |d|
        d.is_a?(Hash) ? (d["domain"] == domain || d[:domain] == domain) : d == domain
      }

      unless exists
        # Extract just the domain strings if we have hashes
        domain_strings = domains.filter_map { |d|
          d.is_a?(Hash) ? (d["domain"] || d[:domain]) : d
        }

        # Add the new domain
        domain_strings << domain

        # Set as simple array of strings
        self[:domains] = domain_strings
      end
    end

    # Get the primary domain
    # @return [String, nil] The primary domain or nil if not set
    def domain
      domains = self[:domains]
      return nil unless domains

      extract_primary_value(domains, "domain")
    end

    # Get all domains
    # @return [Array<String>] Array of domain strings
    def domains_list
      domains = self[:domains]
      return [] unless domains

      case domains
      when Array
        domains.filter_map { |d| extract_field_value(d, "domain") }
      else
        [domain].compact
      end
    end

    private

    # Extract primary value from various data structures
    # @param value [Array, Hash, Object] The value to extract from
    # @param field [String] The field name for hash extraction
    # @return [String, nil] The extracted value
    def extract_primary_value(value, field)
      case value
      when Array
        return nil if value.empty?
        extract_field_value(value.first, field)
      when Hash
        value[field] || value[field.to_sym]
      else
        value.to_s
      end
    end

    # Extract a value from a hash or convert to string
    # @param item [Hash, Object] The item to extract from
    # @param field [String] The field name for hash extraction
    # @return [String] The extracted value
    def extract_field_value(item, field)
      case item
      when Hash
        item[field] || item[field.to_sym]
      else
        item.to_s
      end
    end

    public

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
          company: {
            target_object: "companies",
            target_record_id: company_id
          }
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

      private

      # Build filter for domain field
      def filter_by_domain(value)
        # Strip protocol if present
        normalized_domain = value.sub(/^https?:\/\//, "")
        {
          domains: {
            domain: {
              "$eq": normalized_domain
            }
          }
        }
      end

      # Build filter for name field
      def filter_by_name(value)
        {
          name: {"$contains": value}
        }
      end
    end
  end

  # Convenience alias
  Companies = Company
end
