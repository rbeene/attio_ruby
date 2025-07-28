# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Typed Records Integration", :integration do
  describe "Person records" do
    let(:test_email) { "test-#{SecureRandom.hex(8)}@example.com" }

    it "creates a person using the simple interface" do
      person = Attio::Person.create(
        first_name: "John",
        last_name: "Doe",
        email: test_email,
        phone: "+12125551234",
        job_title: "Software Engineer"
      )

      expect(person).to be_a(Attio::Person)
      expect(person.full_name).to eq("John Doe")
      expect(person.first_name).to eq("John")
      expect(person.last_name).to eq("Doe")
      expect(person.email).to eq(test_email)
      expect(person.phone).to eq("+12125551234")
      expect(person[:job_title]).to eq("Software Engineer")

      # Clean up
      person.destroy
    end

    it "updates name using helper method" do
      person = Attio::Person.create(
        first_name: "Jane",
        last_name: "Smith",
        email: "jane-#{SecureRandom.hex(8)}@example.com"
      )

      # Update using helper
      person.set_name(first: "Janet", middle: "Marie", last: "Johnson")
      person.save

      # Verify update
      updated = Attio::Person.retrieve(person.id["record_id"])
      expect(updated.full_name).to eq("Janet Marie Johnson")
      expect(updated.first_name).to eq("Janet")
      expect(updated[:name].first["middle_name"]).to eq("Marie")

      # Clean up
      updated.destroy
    end

    it "finds people by email" do
      unique_email = "unique-#{SecureRandom.hex(12)}@findtest.com"
      person = Attio::Person.create(
        first_name: "FindMe",
        last_name: "ByEmail",
        email: unique_email
      )

      # Find by email
      found = Attio::Person.find_by_email(unique_email)
      expect(found).not_to be_nil
      expect(found.email).to eq(unique_email)

      # Clean up
      person.destroy
    end

    it "searches people by name" do
      unique_name = "UniqueFirst#{SecureRandom.hex(8)}"
      person = Attio::Person.create(
        first_name: unique_name,
        last_name: "SearchableLast"
      )

      # Search by name
      results = Attio::Person.search(unique_name)
      expect(results.count).to be >= 1

      found = results.any? { |p| p.first_name == unique_name }
      expect(found).to be true

      # Clean up
      person.destroy
    end
  end

  describe "Company records" do
    let(:test_domain) { "test-#{SecureRandom.hex(8)}.com" }

    it "creates a company with simple interface" do
      company = Attio::Company.create(
        name: "Test Company #{SecureRandom.hex(4)}",
        domain: test_domain,
        description: "A test company",
        employee_count: "10-50"
      )

      expect(company).to be_a(Attio::Company)
      expect(company.name).to include("Test Company")
      expect(company.domain).to eq(test_domain)
      expect(company[:description]).to eq("A test company")
      expect(company[:employee_count]).to eq("10-50")

      # Clean up
      company.destroy
    end

    it "manages multiple domains" do
      company = Attio::Company.create(
        name: "Multi Domain Corp #{SecureRandom.hex(4)}",
        domains: ["primary.com", "secondary.com"]
      )

      # Add another domain
      company.add_domain("tertiary.com")
      company.save

      # Verify domains
      expect(company.domains_list).to include("primary.com", "secondary.com", "tertiary.com")

      # Clean up
      company.destroy
    end

    it "finds companies by domain" do
      unique_domain = "unique-#{SecureRandom.hex(12)}.findtest.com"
      company = Attio::Company.create(
        name: "FindMe Company",
        domain: unique_domain
      )

      # Find by domain
      found = Attio::Company.find_by_domain(unique_domain)
      expect(found).not_to be_nil
      expect(found.domain).to eq(unique_domain)

      # Test protocol stripping
      found_with_protocol = Attio::Company.find_by_domain("https://#{unique_domain}")
      expect(found_with_protocol).not_to be_nil
      expect(found_with_protocol.id).to eq(found.id)

      # Clean up
      company.destroy
    end
  end

  describe "Person and Company relationships" do
    it "associates a person with a company" do
      # Create company
      company = Attio::Company.create(
        name: "Employer Corp #{SecureRandom.hex(4)}",
        domain: "employer-#{SecureRandom.hex(8)}.com"
      )

      # Create person with company
      person = Attio::Person.create(
        first_name: "Employee",
        last_name: "Person",
        email: "employee-#{SecureRandom.hex(8)}@example.com",
        company: company
      )

      expect(person[:company]).to eq("companies")

      # Update company association
      new_company = Attio::Company.create(
        name: "New Employer #{SecureRandom.hex(4)}"
      )

      person.company = new_company
      person.save

      # Clean up
      person.destroy
      company.destroy
      new_company.destroy
    end

    it "finds team members of a company" do
      # Create company
      company = Attio::Company.create(
        name: "Team Company #{SecureRandom.hex(4)}"
      )

      # Create employees
      employees = []
      3.times do |i|
        employees << Attio::Person.create(
          first_name: "Employee",
          last_name: "Number#{i}",
          email: "employee#{i}-#{SecureRandom.hex(8)}@teamco.com",
          company: company
        )
      end

      # Find team members
      team = company.team_members
      expect(team.count).to be >= 3

      # Clean up
      employees.each(&:destroy)
      company.destroy
    end
  end

  describe "NameBuilder integration" do
    it "builds complex names correctly" do
      person = Attio::Person.create(
        values: {
          name: Attio::Builders::NameBuilder.new
            .prefix("Dr.")
            .first("Jane")
            .middle("Marie")
            .last("Smith")
            .suffix("PhD")
            .build,
          email_addresses: ["dr.smith-#{SecureRandom.hex(8)}@university.edu"]
        }
      )

      expect(person.full_name).to eq("Dr. Jane Marie Smith PhD")
      expect(person[:name].first["prefix"]).to eq("Dr.")
      expect(person[:name].first["suffix"]).to eq("PhD")

      # Clean up
      person.destroy
    end

    it "parses full names" do
      parsed_name = Attio::Builders::NameBuilder.build("Prof. John Q. Public Jr.")

      person = Attio::Person.create(
        values: {
          name: parsed_name,
          email_addresses: ["prof.public-#{SecureRandom.hex(8)}@example.com"]
        }
      )

      expect(person.full_name).to eq("Prof. John Q. Public Jr.")

      # Clean up
      person.destroy
    end
  end
end
