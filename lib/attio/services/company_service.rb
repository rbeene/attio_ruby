# frozen_string_literal: true

require_relative "base_service"

module Attio
  module Services
    class CompanyService < BaseService
      def initialize(options = {})
        super("companies", options)
      end

      # Find company by name
      def find_by_name(name)
        results = search_by_attribute("name", name)
        results.first
      end

      # Find company by domain
      def find_by_domain(domain)
        results = search_by_attribute("domains", normalize_domain(domain))
        results.first
      end

      # Find or create company by name
      def find_or_create_by_name(name, defaults: {})
        find_or_create_by(
          attribute: "name",
          value: name,
          defaults: defaults
        )
      end

      # Find or create company by domain
      def find_or_create_by_domain(domain, defaults: {})
        normalized_domain = normalize_domain(domain)

        find_or_create_by(
          attribute: "domains",
          value: normalized_domain,
          defaults: defaults.merge(domains: [normalized_domain])
        )
      end

      # Create a company with standard attributes
      def create(name:, domain: nil, industry: nil, size: nil, location: nil, attributes: {})
        values = build_company_values(
          name: name,
          domain: domain,
          industry: industry,
          size: size,
          location: location,
          **attributes
        )

        create_record(values)
      end

      # Update a company's information
      def update(company_id, name: nil, domain: nil, industry: nil, size: nil, attributes: {})
        company = Record.retrieve(object: "companies", record_id: company_id)

        update_values = {}
        update_values[:name] = [{value: name}] if name
        update_values[:domains] = [{value: normalize_domain(domain)}] if domain
        update_values[:industry] = [{value: industry}] if industry
        update_values[:company_size] = [{value: size}] if size

        # Merge additional attributes
        attributes.each do |key, value|
          update_values[key] = normalize_attribute_value(value)
        end

        company.update_attributes(update_values)
      end

      # Get all people in a company
      def people(company_id)
        PersonService.new.by_company(company_id)
      end

      # Add multiple domains to a company
      def add_domains(company_id, domains)
        company = Record.retrieve(object: "companies", record_id: company_id)

        existing_domains = Array(company[:domains]).filter_map { |d| d[:value] }
        new_domains = domains.map { |d| normalize_domain(d) }
        all_domains = (existing_domains + new_domains).uniq

        company.update_attributes(
          domains: all_domains.map { |d| {value: d} }
        )
      end

      # Search companies by industry
      def by_industry(industry, limit: 50)
        search(filters: {industry: industry}, limit: limit)
      end

      # Search companies by size range
      def by_size(min_size: nil, max_size: nil, limit: 50)
        filters = {}

        if min_size && max_size
          filters[:company_size] = {"$gte" => min_size, "$lte" => max_size}
        elsif min_size
          filters[:company_size] = {"$gte" => min_size}
        elsif max_size
          filters[:company_size] = {"$lte" => max_size}
        end

        search(filters: filters, limit: limit)
      end

      # Get companies without any people
      def without_people
        # This would require a more complex query that Attio might not support directly
        # Instead, we can fetch companies and check if they have people
        companies = []

        Record.list(object: "companies").auto_paging_each do |company|
          person_count = PersonService.new.count(filters: {company: company.id})
          companies << company if person_count == 0
        end

        companies
      end

      # Enrich company data from external sources (placeholder)
      def enrich(company_id, source: :clearbit)
        company = Record.retrieve(object: "companies", record_id: company_id)

        # In a real implementation, this would call external APIs
        # For now, we'll just return the company
        case source
        when :clearbit
          enrich_from_clearbit(company)
        when :fullcontact
          enrich_from_fullcontact(company)
        else
          raise ArgumentError, "Unknown enrichment source: #{source}"
        end
      end

      # Merge duplicate companies
      def merge(primary_company_id, duplicate_company_ids)
        transaction do
          primary = Record.retrieve(object: "companies", record_id: primary_company_id)
          duplicates = find_by_ids(duplicate_company_ids)

          # Merge data and relationships
          duplicates.each do |duplicate|
            merge_company_data(primary, duplicate)
            reassign_people(duplicate.id, primary.id)
            duplicate.destroy
          end

          primary
        end
      end

      # Import companies from CSV data
      def import_from_csv(csv_data, mapping: {})
        records = csv_data.map do |row|
          values = {}

          # Map CSV columns to Attio attributes
          mapping.each do |csv_column, attio_attribute|
            value = row[csv_column]
            next if value.nil? || value.empty?

            # Special handling for domains
            if attio_attribute.to_s == "domains"
              value = normalize_domain(value)
            end

            values[attio_attribute] = normalize_attribute_value(value)
          end

          {values: values}
        end

        import(records, on_error: :continue)
      end

      private

      def build_company_values(name:, domain: nil, industry: nil, size: nil, location: nil, **additional)
        values = {}

        values[:name] = [{value: name}]
        values[:domains] = [{value: normalize_domain(domain)}] if domain
        values[:industry] = [{value: industry}] if industry
        values[:company_size] = [{value: size}] if size
        values[:location] = [{value: location}] if location

        # Add any additional attributes
        additional.each do |key, value|
          values[key] = normalize_attribute_value(value)
        end

        values
      end

      def normalize_domain(domain)
        return nil if domain.nil? || domain.empty?

        # Remove protocol and www
        domain.downcase
          .gsub(%r{^https?://}, "")
          .gsub(/^www\./, "")
          .split("/").first
      end

      def normalize_attribute_value(value)
        case value
        when Array
          value.map { |v| {value: v} }
        else
          [{value: value}]
        end
      end

      def merge_company_data(primary, duplicate)
        # Merge domains
        primary_domains = Array(primary[:domains]).filter_map { |d| d[:value] }
        duplicate_domains = Array(duplicate[:domains]).filter_map { |d| d[:value] }
        all_domains = (primary_domains + duplicate_domains).uniq

        if all_domains.size > primary_domains.size
          primary[:domains] = all_domains.map { |d| {value: d} }
        end

        # Merge other attributes
        skip_keys = %w[id created_at name domains]
        duplicate.attributes.each do |key, value|
          next if skip_keys.include?(key.to_s)

          primary_value = primary[key]
          next if primary_value && !primary_value.empty?

          primary[key] = value
        end

        primary.save
      end

      def reassign_people(from_company_id, to_company_id)
        people = PersonService.new.by_company(from_company_id)

        people.each do |person|
          person.update_attributes(
            company: [{target_object: "companies", target_record: to_company_id}]
          )
        end
      end

      def enrich_from_clearbit(company)
        # Placeholder for Clearbit enrichment
        # In reality, this would call the Clearbit API
        company
      end

      def enrich_from_fullcontact(company)
        # Placeholder for FullContact enrichment
        # In reality, this would call the FullContact API
        company
      end
    end
  end
end
