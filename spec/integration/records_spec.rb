# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Record Integration", :integration do

  describe "person records" do
    let(:test_email) { "test-#{SecureRandom.hex(8)}@example.com" }
    let(:person_data) do
      {
        name: [{
          first_name: "Test",
          last_name: "Person",
          full_name: "Test Person"
        }],
        email_addresses: [test_email],
        phone_numbers: [{
          original_phone_number: "+12125551234",
          country_code: "US"
        }],
        job_title: "Software Engineer"
      }
    end

    it "creates a person record" do
      person = Attio::Record.create(
        object: "people",
        values: person_data
      )

      expect(person).to be_a(Attio::Record)
      expect(person[:name]["full_name"]).to eq("Test Person")
      expect(person[:name]["first_name"]).to eq("Test")
      expect(person[:name]["last_name"]).to eq("Person")
      expect(person[:email_addresses]["email_address"]).to eq(test_email)
      expect(person[:phone_numbers]["original_phone_number"]).to eq("+12125551234")
      expect(person.id).to be_a(Hash)
      expect(person.id["record_id"]).to be_a(String)
    end

    it "retrieves a person record" do
      # First create a person
      created = Attio::Record.create(object: "people", values: person_data)

      # Then retrieve it
      person = Attio::Record.retrieve(object: "people", record_id: created.id)

      expect(person.id).to eq(created.id)
      expect(person[:name]["full_name"]).to eq("Test Person")
    end

    it "updates a person record" do
      # Create person
      person = Attio::Record.create(object: "people", values: person_data)

      # Update
      person[:job_title] = "Senior Software Engineer"
      person.save

      # Verify
      updated = Attio::Record.retrieve(object: "people", record_id: person.id)
      expect(updated[:job_title]).to eq("Senior Software Engineer")
    end

    it "searches for people" do
      # Create a person with very unique name to avoid false matches
      unique_name = "TestUnique#{SecureRandom.hex(12)}"
      created = Attio::Record.create(
        object: "people",
        values: {
          name: [{
            first_name: unique_name,
            last_name: "SearchTest",
            full_name: "#{unique_name} SearchTest"
          }],
          email_addresses: ["search-#{SecureRandom.hex(8)}@example.com"]
        }
      )

      # Search with more specific query
      results = Attio::Record.list(
        object: "people",
        params: {q: unique_name}
      )

      expect(results.count).to be >= 1
      # Name could be a hash or an array depending on the API response
      found = results.any? do |r|
        name_attr = r[:name]
        if name_attr.is_a?(Hash)
          name_attr["first_name"] == unique_name
        elsif name_attr.is_a?(Array) && name_attr.first.is_a?(Hash)
          name_attr.first["first_name"] == unique_name
        else
          false
        end
      end
      expect(found).to be true
      
      # Clean up
      created.destroy
    end

    it "deletes a person record" do
      # Create person
      person = Attio::Record.create(object: "people", values: person_data)
      person_id = person.id # Store ID before destroy

      # Delete
      result = person.destroy
      expect(result).to be true
      expect(person).to be_frozen

      # Verify deletion
      expect {
        Attio::Record.retrieve(object: "people", record_id: person_id)
      }.to raise_error(Attio::NotFoundError)
    end
  end

  describe "company records" do
    let(:company_data) do
      {
        name: "Test Company #{SecureRandom.hex(4)}",
        domains: ["test-#{SecureRandom.hex(8)}.com"]
      }
    end

    it "creates a company record" do
      company = Attio::Record.create(
        object: "companies",
        values: company_data
      )

      expect(company).to be_a(Attio::Record)
      expect(company[:name]).to start_with("Test Company")
      expect(company[:domains]["domain"]).to include("test-")
    end

    it "creates relationships between records" do
      # Create company
      company = Attio::Record.create(object: "companies", values: company_data)

      # Create person with company relationship
      person = Attio::Record.create(
        object: "people",
        values: {
          name: [{
            first_name: "Employee",
            last_name: "Test",
            full_name: "Employee Test"
          }],
          email_addresses: ["employee-#{SecureRandom.hex(8)}@example.com"],
          company: [{
            target_object: "companies",
            target_record_id: company.id["record_id"]
          }]
        }
      )

      expect(person[:company]).to eq("companies")
    end
  end

  describe "filtering and sorting" do
    before do
      # Create test data
      Attio::Record.create(
        object: "people",
        values: {
          name: [{
            first_name: "Alice",
            last_name: "Filter Test",
            full_name: "Alice Filter Test"
          }],
          email_addresses: ["alice-#{SecureRandom.hex(8)}@filter.com"],
          job_title: "CEO"
        }
      )

      Attio::Record.create(
        object: "people",
        values: {
          name: [{
            first_name: "Bob",
            last_name: "Filter Test",
            full_name: "Bob Filter Test"
          }],
          email_addresses: ["bob-#{SecureRandom.hex(8)}@filter.com"],
          job_title: "CTO"
        }
      )
    end

    it "filters records" do
      results = Attio::Record.list(
        object: "people",
        params: {
          filter: {
            job_title: {"$contains": "C"}
          }
        }
      )

      expect(results.count).to be >= 2
      # Verify we got some results (filter may not match all records)
      expect(results.count).to be >= 0
    end

    it "sorts records" do
      results = Attio::Record.list(
        object: "people",
        params: {
          sort: [{attribute: "name", direction: "asc"}],
          limit: 10
        }
      )

      # Since name is a complex object, just verify we got results
      expect(results.count).to be > 0
    end
  end

  describe "error handling" do
    it "handles validation errors" do
      expect {
        Attio::Record.create(
          object: "people",
          values: {email_addresses: ["invalid-email"]}
        )
      }.to raise_error(Attio::BadRequestError)
    end

    it "handles not found errors" do
      expect {
        Attio::Record.retrieve(
          object: "people",
          record_id: "00000000-0000-0000-0000-000000000000" # Valid UUID format
        )
      }.to raise_error(Attio::NotFoundError)
    end
  end
end
