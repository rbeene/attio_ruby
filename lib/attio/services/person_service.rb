# frozen_string_literal: true

require_relative "base_service"

module Attio
  module Services
    class PersonService < BaseService
      def initialize(options = {})
        super("people", options)
      end

      # Find person by email
      def find_by_email(email)
        results = search_by_attribute("email_addresses", email)
        results.first
      end

      # Find or create person by email
      def find_or_create_by_email(email, defaults: {})
        find_or_create_by(
          attribute: "email_addresses",
          value: email,
          defaults: defaults
        )
      end

      # Create a person with standard attributes
      def create(name: nil, email: nil, phone: nil, company: nil, title: nil, attributes: {})
        values = build_person_values(
          name: name,
          email: email,
          phone: phone,
          company: company,
          title: title,
          **attributes
        )

        create_record(values)
      end

      # Update a person's information
      def update(person_id, name: nil, email: nil, phone: nil, title: nil, attributes: {})
        person = Record.retrieve(object: "people", record_id: person_id)

        update_values = {}
        update_values[:name] = [{value: name}] if name
        update_values[:email_addresses] = [{value: email}] if email
        update_values[:phone_numbers] = [{value: phone}] if phone
        update_values[:job_title] = [{value: title}] if title

        # Merge additional attributes
        attributes.each do |key, value|
          update_values[key] = normalize_attribute_value(value)
        end

        person.update_attributes(update_values)
      end

      # Search people by name
      def search_by_name(name, limit: 20)
        search(query: name, limit: limit)
      end

      # Get people in a specific company
      def by_company(company_id)
        search(filters: {company: company_id})
      end

      # Add person to a list
      def add_to_list(person_id, list_id)
        ListEntry.create(list_id: list_id, record_id: person_id)
      end

      # Get lists a person belongs to
      def lists(person_id)
        person = Record.retrieve(object: "people", record_id: person_id)
        person.lists
      end

      # Add a note to a person
      def add_note(person_id, content, format: "plaintext")
        Note.create(
          parent_object: "people",
          parent_record_id: person_id,
          content: content,
          format: format
        )
      end

      # Get notes for a person
      def notes(person_id)
        Note.for_record(object: "people", record_id: person_id)
      end

      # Merge duplicate people
      def merge(primary_person_id, duplicate_person_ids)
        transaction do
          primary = Record.retrieve(object: "people", record_id: primary_person_id)
          duplicates = find_by_ids(duplicate_person_ids)

          # Merge data from duplicates into primary
          duplicates.each do |duplicate|
            merge_person_data(primary, duplicate)
            duplicate.destroy
          end

          primary
        end
      end

      # Import people from CSV data
      def import_from_csv(csv_data, mapping: {})
        records = csv_data.map do |row|
          values = {}

          # Map CSV columns to Attio attributes
          mapping.each do |csv_column, attio_attribute|
            value = row[csv_column]
            next if value.nil? || value.empty?

            values[attio_attribute] = normalize_attribute_value(value)
          end

          {values: values}
        end

        import(records, on_error: :continue)
      end

      private

      def build_person_values(name: nil, email: nil, phone: nil, company: nil, title: nil, **additional)
        values = {}

        values[:name] = [{value: name}] if name
        values[:email_addresses] = [{value: email}] if email
        values[:phone_numbers] = [{value: phone}] if phone
        values[:job_title] = [{value: title}] if title

        if company
          # Company can be a record ID or a name
          if company.match?(/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i)
            values[:company] = [{target_object: "companies", target_record: company}]
          else
            # Find or create company by name
            company_service = CompanyService.new
            company_record = company_service.find_or_create_by_name(company)
            values[:company] = [{target_object: "companies", target_record: company_record.id}]
          end
        end

        # Add any additional attributes
        additional.each do |key, value|
          values[key] = normalize_attribute_value(value)
        end

        values
      end

      def normalize_attribute_value(value)
        case value
        when Array
          value.map { |v| {value: v} }
        else
          [{value: value}]
        end
      end

      def merge_person_data(primary, duplicate)
        # Get all attribute values from duplicate
        skip_keys = %w[id created_at]
        duplicate.attributes.each do |key, value|
          next if skip_keys.include?(key.to_s)

          # Skip if primary already has this value
          primary_value = primary[key]
          next if primary_value && !primary_value.empty?

          # Copy value from duplicate to primary
          primary[key] = value
        end

        primary.save
      end
    end
  end
end
