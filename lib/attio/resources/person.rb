# frozen_string_literal: true

require_relative "typed_record"

module Attio
  # Represents a person record in Attio
  # Provides convenient methods for working with people and their attributes
  class Person < TypedRecord
    object_type "people"

    # Set the person's name using a more intuitive interface
    # @param first [String] First name
    # @param last [String] Last name
    # @param middle [String] Middle name (optional)
    # @param full [String] Full name (optional, will be generated if not provided)
    def set_name(first: nil, last: nil, middle: nil, full: nil)
      name_data = {}
      name_data[:first_name] = first if first
      name_data[:last_name] = last if last
      name_data[:middle_name] = middle if middle

      # Generate full name if not provided
      if full
        name_data[:full_name] = full
      elsif first || last
        parts = [first, middle, last].compact
        name_data[:full_name] = parts.join(" ") unless parts.empty?
      end

      # Attio expects name as an array with a single hash
      self[:name] = [name_data] unless name_data.empty?
    end

    # Set the person's name using a hash or string
    # @param name_value [Hash, String] Either a hash with first/last/middle/full keys or a full name string
    def name=(name_value)
      case name_value
      when Hash
        set_name(**name_value)
      when String
        set_name(full: name_value)
      else
        raise ArgumentError, "Name must be a Hash or String"
      end
    end

    # Get the person's full name
    # @return [String, nil] The full name or nil if not set
    def full_name
      extract_name_field("full_name")
    end

    # Get the person's first name
    # @return [String, nil] The first name or nil if not set
    def first_name
      extract_name_field("first_name")
    end

    # Get the person's last name
    # @return [String, nil] The last name or nil if not set
    def last_name
      extract_name_field("last_name")
    end

    private

    # Extract a field from the name data structure
    # @param field [String] The field to extract
    # @return [String, nil] The field value or nil
    def extract_name_field(field)
      name_value = self[:name]
      return nil unless name_value

      name_hash = normalize_to_hash(name_value)
      name_hash[field] || name_hash[field.to_sym]
    end

    # Extract primary value from various data structures
    # @param value [Array, Hash, Object] The value to extract from
    # @param field [String] The field name for hash extraction
    # @return [String, nil] The extracted value
    def extract_primary_value(value, field)
      case value
      when Array
        return nil if value.empty?
        first_item = value.first
        if first_item.is_a?(Hash)
          first_item[field] || first_item[field.to_sym]
        else
          first_item.to_s
        end
      when Hash
        value[field] || value[field.to_sym]
      else
        value.to_s
      end
    end

    # Normalize various name formats to a hash
    # @param value [Array, Hash] The value to normalize
    # @return [Hash] The normalized hash
    def normalize_to_hash(value)
      case value
      when Array
        value.first.is_a?(Hash) ? value.first : {}
      when Hash
        value
      else
        {}
      end
    end

    public

    # Add an email address
    # @param email [String] The email address to add
    def add_email(email)
      emails = self[:email_addresses] || []
      # Ensure it's an array
      emails = [emails] unless emails.is_a?(Array)

      # Add the email if it's not already present
      emails << email unless emails.include?(email)
      self[:email_addresses] = emails
    end

    # Get the primary email address
    # @return [String, nil] The primary email or nil if not set
    def email
      emails = self[:email_addresses]
      return nil unless emails

      extract_primary_value(emails, "email_address")
    end

    # Add a phone number
    # @param number [String] The phone number
    # @param country_code [String] The country code (e.g., "US")
    def add_phone(number, country_code: "US")
      phones = self[:phone_numbers] || []
      phones = [phones] unless phones.is_a?(Array)

      phone_data = {
        original_phone_number: number,
        country_code: country_code
      }

      phones << phone_data
      self[:phone_numbers] = phones
    end

    # Get the primary phone number
    # @return [String, nil] The primary phone number or nil if not set
    def phone
      phones = self[:phone_numbers]
      return nil unless phones

      extract_primary_value(phones, "original_phone_number")
    end

    # Set the job title
    # @param title [String] The job title
    def job_title=(title)
      self[:job_title] = title
    end

    # Associate with a company
    # @param company [Company, String] A Company instance or company ID
    def company=(company)
      if company.is_a?(Company)
        # Extract ID properly from company instance
        company_id = company.id.is_a?(Hash) ? company.id["record_id"] : company.id
        self[:company] = [{
          target_object: "companies",
          target_record_id: company_id
        }]
      elsif company.is_a?(String)
        self[:company] = [{
          target_object: "companies",
          target_record_id: company
        }]
      elsif company.nil?
        self[:company] = nil
      else
        raise ArgumentError, "Company must be a Company instance or ID string"
      end
    end

    class << self
      # Create a person with a simplified interface
      # @param attributes [Hash] Person attributes
      # @option attributes [String] :first_name First name
      # @option attributes [String] :last_name Last name
      # @option attributes [String] :email Email address
      # @option attributes [String] :phone Phone number
      # @option attributes [String] :job_title Job title
      # @option attributes [Hash] :values Raw values hash (for advanced use)
      def create(first_name: nil, last_name: nil, full_name: nil, email: nil, phone: nil,
        job_title: nil, company: nil, values: {}, **opts)
        # Build the values hash
        values[:name] ||= []
        if first_name || last_name || full_name
          name_data = {}

          # If only full_name is provided, try to parse it
          if full_name && !first_name && !last_name
            parts = full_name.split(" ")
            if parts.length >= 2
              name_data[:first_name] = parts.first
              name_data[:last_name] = parts[1..].join(" ")
            else
              name_data[:first_name] = full_name
            end
            name_data[:full_name] = full_name
          else
            name_data[:first_name] = first_name if first_name
            name_data[:last_name] = last_name if last_name
            name_data[:full_name] = full_name || [first_name, last_name].compact.join(" ")
          end

          values[:name] = [name_data]
        end

        values[:email_addresses] = [email] if email && !values[:email_addresses]

        if phone && !values[:phone_numbers]
          values[:phone_numbers] = [{
            original_phone_number: phone,
            country_code: opts.delete(:country_code) || "US"
          }]
        end

        values[:job_title] = job_title if job_title && !values[:job_title]

        if company && !values[:company]
          company_ref = if company.is_a?(Company)
            company_id = company.id.is_a?(Hash) ? company.id["record_id"] : company.id
            {
              target_object: "companies",
              target_record_id: company_id
            }
          elsif company.is_a?(String)
            {
              target_object: "companies",
              target_record_id: company
            }
          end
          values[:company] = [company_ref] if company_ref
        end

        super(values: values, **opts)
      end

      # Find people by email
      # @param email [String] Email address to search for
      def find_by_email(email, **opts)
        list(**opts.merge(
          filter: {
            email_addresses: {
              email_address: {
                "$eq": email
              }
            }
          }
        )).first
      end

      # Search people by query
      # @param query [String] Query to search for
      def search(query, **opts)
        # Search across name fields
        list(**opts.merge(
          filter: {
            "$or": [
              {name: {first_name: {"$contains": query}}},
              {name: {last_name: {"$contains": query}}},
              {name: {full_name: {"$contains": query}}}
            ]
          }
        ))
      end

      # Find people by name
      # @param name [String] Name to search for
      def find_by_name(name, **opts)
        results = search(name, **opts)
        results.first
      end
    end
  end

  # Convenience alias
  People = Person
end
