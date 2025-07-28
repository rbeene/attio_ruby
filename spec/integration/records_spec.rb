# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Record Integration", :integration do
  before do
    Attio.configure do |config|
      config.api_key = ENV["ATTIO_API_KEY"]
    end
  end

  describe "person records" do
    let(:test_email) { "test-#{SecureRandom.hex(8)}@example.com" }
    let(:person_data) do
      {
        name: "Test Person",
        email_addresses: test_email,
        phone_numbers: "+1-555-0123",
        job_title: "Software Engineer"
      }
    end

    it "creates a person record" do
      VCR.use_cassette("records/create_person") do
        person = Attio::Record.create(
          object: "people",
          values: person_data
        )

        expect(person).to be_a(Attio::Record)
        expect(person[:name]).to eq("Test Person")
        expect(person[:email_addresses]).to include(test_email)
        expect(person.id).to be_present
      end
    end

    it "retrieves a person record" do
      VCR.use_cassette("records/retrieve_person") do
        # First create a person
        created = Attio::Record.create(object: "people", values: person_data)

        # Then retrieve it
        person = Attio::Record.retrieve(object: "people", record_id: created.id)

        expect(person.id).to eq(created.id)
        expect(person[:name]).to eq("Test Person")
      end
    end

    it "updates a person record" do
      VCR.use_cassette("records/update_person") do
        # Create person
        person = Attio::Record.create(object: "people", values: person_data)

        # Update
        person[:job_title] = "Senior Software Engineer"
        person[:tags] = ["vip", "customer"]
        person.save

        # Verify
        updated = Attio::Record.retrieve(object: "people", record_id: person.id)
        expect(updated[:job_title]).to eq("Senior Software Engineer")
        expect(updated[:tags]).to include("vip", "customer")
      end
    end

    it "searches for people" do
      VCR.use_cassette("records/search_people") do
        # Create a person with unique name
        unique_name = "Unique #{SecureRandom.hex(8)}"
        Attio::Record.create(
          object: "people",
          values: {name: unique_name, email_addresses: test_email}
        )

        # Search
        results = Attio::Record.list(
          object: "people",
          params: {q: unique_name}
        )

        expect(results.count).to be >= 1
        expect(results.first[:name]).to include(unique_name)
      end
    end

    it "deletes a person record" do
      VCR.use_cassette("records/delete_person") do
        # Create person
        person = Attio::Record.create(object: "people", values: person_data)

        # Delete
        result = person.destroy
        expect(result).to be true
        expect(person).to be_frozen

        # Verify deletion
        expect {
          Attio::Record.retrieve(object: "people", record_id: person.id)
        }.to raise_error(Attio::Errors::NotFoundError)
      end
    end
  end

  describe "company records" do
    let(:company_data) do
      {
        name: "Test Company #{SecureRandom.hex(4)}",
        domains: "test-#{SecureRandom.hex(8)}.com",
        industry: "Technology",
        company_size: "50-100"
      }
    end

    it "creates a company record" do
      VCR.use_cassette("records/create_company") do
        company = Attio::Record.create(
          object: "companies",
          values: company_data
        )

        expect(company).to be_a(Attio::Record)
        expect(company[:name]).to start_with("Test Company")
        expect(company[:industry]).to eq("Technology")
      end
    end

    it "creates relationships between records" do
      VCR.use_cassette("records/create_relationship") do
        # Create company
        company = Attio::Record.create(object: "companies", values: company_data)

        # Create person with company relationship
        person = Attio::Record.create(
          object: "people",
          values: {
            name: "Employee Test",
            email_addresses: "employee-#{SecureRandom.hex(8)}@example.com",
            company: [{
              target_object: "companies",
              target_record: company.id
            }]
          }
        )

        expect(person[:company]).to be_present
        expect(person[:company].first["target_record"]).to eq(company.id)
      end
    end
  end

  describe "filtering and sorting" do
    before do
      VCR.use_cassette("records/setup_filter_data") do
        # Create test data
        Attio::Record.create(
          object: "people",
          values: {
            name: "Alice Filter Test",
            email_addresses: "alice@filter.com",
            job_title: "CEO"
          }
        )

        Attio::Record.create(
          object: "people",
          values: {
            name: "Bob Filter Test",
            email_addresses: "bob@filter.com",
            job_title: "CTO"
          }
        )
      end
    end

    it "filters records" do
      VCR.use_cassette("records/filter") do
        results = Attio::Record.list(
          object: "people",
          params: {
            filter: {
              job_title: {"$contains": "C"}
            }
          }
        )

        expect(results.count).to be >= 2
        expect(results.all? { |r| r[:job_title]&.include?("C") }).to be true
      end
    end

    it "sorts records" do
      VCR.use_cassette("records/sort") do
        results = Attio::Record.list(
          object: "people",
          params: {
            sort: [{attribute: "name", direction: "asc"}],
            limit: 10
          }
        )

        names = results.filter_map { |r| r[:name] }
        expect(names).to eq(names.sort)
      end
    end
  end

  describe "error handling" do
    it "handles validation errors" do
      VCR.use_cassette("records/validation_error") do
        expect {
          Attio::Record.create(
            object: "people",
            values: {email_addresses: "invalid-email"}
          )
        }.to raise_error(Attio::Errors::InvalidRequestError)
      end
    end

    it "handles not found errors" do
      VCR.use_cassette("records/not_found") do
        expect {
          Attio::Record.retrieve(
            object: "people",
            record_id: "non-existent-id"
          )
        }.to raise_error(Attio::Errors::NotFoundError)
      end
    end
  end
end
