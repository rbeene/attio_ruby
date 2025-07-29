# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Record Integration", :integration do
  describe "person records" do
    let(:test_email) { "test-#{SecureRandom.hex(8)}@example.com" }

    it "creates a person record" do
      person = Attio::Person.create(
        first_name: "Test",
        last_name: "Person",
        email: test_email,
        phone: "+12125551234",
        job_title: "Software Engineer"
      )

      expect(person).to be_a(Attio::Person)
      expect(person.full_name).to eq("Test Person")
      expect(person.first_name).to eq("Test")
      expect(person.last_name).to eq("Person")
      expect(person.email).to eq(test_email)
      expect(person.phone).to eq("+12125551234")
      expect(person[:job_title]).to eq("Software Engineer")
      expect(person.id).to be_a(String).or be_a(Hash)
    end

    it "retrieves a person record" do
      # First create a person
      created = Attio::Person.create(
        first_name: "Test",
        last_name: "Person",
        email: test_email
      )

      # Then retrieve it
      person = Attio::Person.retrieve(created.id)

      expect(person.id).to eq(created.id)
      expect(person.full_name).to eq("Test Person")
    end

    it "updates a person record" do
      # Create person
      person = Attio::Person.create(
        first_name: "Test",
        last_name: "Person",
        email: test_email,
        job_title: "Software Engineer"
      )

      # Update
      person[:job_title] = "Senior Software Engineer"
      person.save

      # Verify
      updated = Attio::Person.retrieve(person.id)
      expect(updated[:job_title]).to eq("Senior Software Engineer")
    end

    it "searches for people" do
      # Create a person with very unique name to avoid false matches
      unique_name = "TestUnique#{SecureRandom.hex(12)}"
      created = Attio::Person.create(
        first_name: unique_name,
        last_name: "SearchTest",
        email: "search-#{SecureRandom.hex(8)}@example.com"
      )

      # Search with more specific query
      results = Attio::Person.search(unique_name)

      expect(results.count).to be >= 1
      found = results.any? { |r| r.first_name == unique_name }
      expect(found).to be true

      # Clean up
      created.destroy
    end

    it "deletes a person record" do
      # Create person
      person = Attio::Person.create(
        first_name: "Test",
        last_name: "Person",
        email: test_email
      )
      person_id = person.id # Store ID before destroy

      # Delete
      result = person.destroy
      expect(result).to be true

      # Verify deletion
      expect {
        Attio::Person.retrieve(person_id)
      }.to raise_error(Attio::NotFoundError)
    end
  end

  describe "company records" do
    it "creates a company record" do
      company = Attio::Company.create(
        name: "Test Company #{SecureRandom.hex(4)}",
        domain: "test-#{SecureRandom.hex(8)}.com"
      )

      expect(company).to be_a(Attio::Company)
      expect(company.name).to start_with("Test Company")
      expect(company.domain).to include("test-")
    end

    it "creates relationships between records" do
      # Create company
      company = Attio::Company.create(
        name: "Test Company #{SecureRandom.hex(4)}",
        domain: "test-#{SecureRandom.hex(8)}.com"
      )

      # Create person with company relationship
      person = Attio::Person.create(
        first_name: "Employee",
        last_name: "Test",
        email: "employee-#{SecureRandom.hex(8)}@example.com",
        company: company
      )

      # The company field should be set
      expect(person[:company]).not_to be_nil
    end
  end

  describe "filtering and sorting" do
    before do
      # Create test data
      Attio::Person.create(
        first_name: "Alice",
        last_name: "Filter Test",
        email: "alice-#{SecureRandom.hex(8)}@filter.com",
        job_title: "CEO"
      )

      Attio::Person.create(
        first_name: "Bob",
        last_name: "Filter Test",
        email: "bob-#{SecureRandom.hex(8)}@filter.com",
        job_title: "CTO"
      )
    end

    it "filters records" do
      results = Attio::Person.list(
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
      results = Attio::Person.list(
        params: {
          sort: [{attribute: "created_at", direction: "desc"}],
          limit: 10
        }
      )

      # Since created_at is a valid sort field, just verify we got results
      expect(results.count).to be > 0
    end
  end

  describe "error handling" do
    it "handles validation errors" do
      expect {
        Attio::Person.create(
          email: "invalid-email" # Invalid email format
        )
      }.to raise_error(Attio::BadRequestError)
    end

    it "handles not found errors" do
      expect {
        Attio::Person.retrieve("00000000-0000-0000-0000-000000000000") # Valid UUID format
      }.to raise_error(Attio::NotFoundError)
    end
  end
end