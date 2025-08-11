# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Combined filtering", :integration do
  let(:unique_id) { "#{Time.now.to_i}-#{rand(10000)}" }
  let(:test_email) { "combined-filter-test-#{unique_id}@example.com" }
  let(:test_name) { "FilterTest#{unique_id}" }

  let!(:test_people) do
    [
      Attio::Person.create(
        first_name: test_name,
        last_name: "User One",
        email: test_email
      ),
      Attio::Person.create(
        first_name: test_name,
        last_name: "User Two",
        email: "different-#{Time.now.to_i}-#{rand(1000)}@example.com"
      ),
      Attio::Person.create(
        first_name: "Different",
        last_name: "Name",
        email: "another-#{Time.now.to_i}-#{rand(1000)}@example.com"
      )
    ]
  end

  before do
    # Give the API a moment to index
    sleep 2
  end

  after do
    # Clean up test data
    test_people.each do |person|
      person.destroy
    rescue
      nil
    end
  end

  describe "Person.find_by with combined conditions" do
    it "finds person matching BOTH email AND name" do
      # This should find only person1 who has both the email AND name
      result = Attio::Person.find_by(email: test_email, name: test_name)

      expect(result).not_to be_nil
      # Check the attributes match what we're looking for
      expect(result.email).to eq(test_email)
      expect(result.first_name).to eq(test_name)
      expect(result.last_name).to eq("User One")
    end

    it "returns nil when no person matches both conditions" do
      # This should return nil because no person has this combination
      result = Attio::Person.find_by(
        email: "nonexistent@example.com",
        name: test_name
      )

      expect(result).to be_nil
    end

    it "finds person with just email filter" do
      # This should find only the person with this email
      results = Attio::Person.list(params: {
        filter: {
          email_addresses: {
            email_address: {"$eq": test_email}
          }
        }
      })

      # Filter by our unique email to find only our test person
      expect(results.count).to be >= 1

      # Find our specific test person
      our_person = results.find { |p| p.first_name == test_name && p.last_name == "User One" }
      expect(our_person).not_to be_nil
      expect(our_person.email).to eq(test_email)
    end

    it "finds person with just name filter" do
      # This should find people with matching name
      results = Attio::Person.list(params: {
        filter: {
          "$or": [
            {name: {first_name: {"$contains": test_name}}},
            {name: {last_name: {"$contains": test_name}}},
            {name: {full_name: {"$contains": test_name}}}
          ]
        }
      })

      # Should find at least our two test people with this name
      our_people = results.select { |p| p.first_name == test_name }
      expect(our_people.count).to be >= 2

      # Check we found our specific test people
      last_names = our_people.map(&:last_name)
      expect(last_names).to include("User One", "User Two")
    end
  end

  describe "Company.find_by with combined conditions" do
    let(:company_unique_id) { "#{Time.now.to_i}-#{rand(10000)}" }
    let(:company_data) do
      {
        name: "CombinedFilter Corp #{company_unique_id}",
        domain: "combined-filter-#{company_unique_id}.com"
      }
    end

    let!(:test_companies) do
      [
        Attio::Company.create(
          name: company_data[:name],
          domain: company_data[:domain]
        ),
        Attio::Company.create(
          name: company_data[:name],
          domain: "different-#{Time.now.to_i}.com"
        )
      ]
    end

    before do
      sleep 1
    end

    after do
      test_companies.each do |company|
        company.destroy
      rescue
        nil
      end
    end

    it "finds company matching BOTH domain AND name" do
      result = Attio::Company.find_by(domain: company_data[:domain], name: company_data[:name])

      expect(result).not_to be_nil
      # Check the attributes match what we're looking for
      expect(result.domain).to eq(test_companies[0].domain)
      expect(result.name).to eq(test_companies[0].name)
    end
  end

  describe "Person.find_by with job_title and company" do
    let(:unique_id) { "#{Time.now.to_i}-#{rand(10000)}" }
    let(:job_title) { "Senior Engineer #{unique_id}" }
    let(:company_name) { "Tech Corp #{unique_id}" }

    let!(:company) do
      Attio::Company.create(
        name: company_name
      )
    end

    let!(:test_people) do
      [
        Attio::Person.create(
          first_name: "Engineer",
          last_name: "One",
          email: "engineer1-#{unique_id}@example.com",
          job_title: job_title,
          company: company
        ),
        Attio::Person.create(
          first_name: "Engineer",
          last_name: "Two",
          email: "engineer2-#{unique_id}@example.com",
          job_title: job_title
        ),
        Attio::Person.create(
          first_name: "Manager",
          last_name: "Three",
          email: "manager3-#{unique_id}@example.com",
          job_title: "Product Manager",
          company: company
        )
      ]
    end

    before do
      sleep 2
    end

    after do
      test_people.each do |person|
        person.destroy
      rescue
        nil
      end
      begin
        company.destroy
      rescue
        nil
      end
    end

    it "finds person by job_title only" do
      result = Attio::Person.find_by(job_title: job_title)

      expect(result).not_to be_nil
      expect(result[:job_title]).to eq(job_title)
    end

    it "finds person by company reference" do
      # This might need special handling for company references
      company_id = company.id.is_a?(Hash) ? company.id["record_id"] : company.id

      result = Attio::Person.find_by(company: {
        target_object: "companies",
        target_record_id: company_id
      })

      expect(result).not_to be_nil
      # Should find one of the people associated with the company
      expect([test_people[0].id, test_people[2].id]).to include(result.id)
    end
  end
end
