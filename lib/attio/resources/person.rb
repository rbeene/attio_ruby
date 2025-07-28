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

    # Get the person's full name
    # @return [String, nil] The full name or nil if not set
    def full_name
      name_value = self[:name]
      return nil unless name_value

      if name_value.is_a?(Array) && name_value.first.is_a?(Hash)
        name_value.first["full_name"] || name_value.first[:full_name]
      elsif name_value.is_a?(Hash)
        name_value["full_name"] || name_value[:full_name]
      end
    end

    # Get the person's first name
    # @return [String, nil] The first name or nil if not set
    def first_name
      name_value = self[:name]
      return nil unless name_value

      if name_value.is_a?(Array) && name_value.first.is_a?(Hash)
        name_value.first["first_name"] || name_value.first[:first_name]
      elsif name_value.is_a?(Hash)
        name_value["first_name"] || name_value[:first_name]
      end
    end

    # Get the person's last name
    # @return [String, nil] The last name or nil if not set
    def last_name
      name_value = self[:name]
      return nil unless name_value

      if name_value.is_a?(Array) && name_value.first.is_a?(Hash)
        name_value.first["last_name"] || name_value.first[:last_name]
      elsif name_value.is_a?(Hash)
        name_value["last_name"] || name_value[:last_name]
      end
    end

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

      if emails.is_a?(Array) && !emails.empty?
        # If it's an array of hashes (from API response)
        if emails.first.is_a?(Hash)
          emails.first["email_address"] || emails.first[:email_address]
        else
          # If it's an array of strings
          emails.first
        end
      elsif emails.is_a?(Hash)
        emails["email_address"] || emails[:email_address]
      else
        emails.to_s
      end
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

      if phones.is_a?(Array) && !phones.empty?
        phone = phones.first
        if phone.is_a?(Hash)
          phone["original_phone_number"] || phone[:original_phone_number]
        else
          phone.to_s
        end
      elsif phones.is_a?(Hash)
        phones["original_phone_number"] || phones[:original_phone_number]
      end
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
      def create(first_name: nil, last_name: nil, email: nil, phone: nil,
        job_title: nil, company: nil, values: {}, **opts)
        # Build the values hash
        values[:name] ||= []
        if first_name || last_name
          name_data = {}
          name_data[:first_name] = first_name if first_name
          name_data[:last_name] = last_name if last_name
          name_data[:full_name] = [first_name, last_name].compact.join(" ")
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
        list(**opts.merge(params: {
          filter: {
            email_addresses: {"$contains": email}
          }
        })).first
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
