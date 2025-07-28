# frozen_string_literal: true

require "spec_helper"

RSpec.describe Attio::Person do
  describe ".object_type" do
    it "returns 'people'" do
      expect(described_class.object_type).to eq("people")
    end
  end

  describe "class aliases" do
    it "provides People as an alias" do
      expect(Attio::People).to eq(described_class)
    end
  end

  describe ".create" do
    it "creates a person with simple parameters" do
      allow(described_class).to receive(:execute_request).and_return({data: {id: {record_id: "123"}}})

      person = described_class.create(
        first_name: "John",
        last_name: "Doe",
        email: "john@example.com",
        phone: "+1234567890",
        job_title: "Developer"
      )

      expect(person).to be_a(described_class)
    end

    it "sends correct parameters when creating a person" do
      expected_values = {
        name: [{
          first_name: "John",
          last_name: "Doe",
          full_name: "John Doe"
        }],
        email_addresses: ["john@example.com"],
        phone_numbers: [{
          original_phone_number: "+1234567890",
          country_code: "US"
        }],
        job_title: "Developer"
      }

      allow(described_class).to receive(:execute_request).with(
        :POST,
        "records",
        {data: {object: "people", values: expected_values}},
        {}
      ).and_return({data: {id: {record_id: "123"}}})

      result = described_class.create(
        first_name: "John",
        last_name: "Doe",
        email: "john@example.com",
        phone: "+1234567890",
        job_title: "Developer"
      )
      expect(result).to be_a(described_class)
    end

    it "handles company association" do
      company = Attio::Company.new({id: {record_id: "company-123"}})

      allow(described_class).to receive(:execute_request).and_return({data: {id: {record_id: "123"}}})

      result = described_class.create(
        first_name: "John",
        last_name: "Doe",
        company: company
      )
      expect(result).to be_a(described_class)
    end

    it "allows custom country code for phone" do
      expect(described_class).to receive(:execute_request) do |_, _, params, _|
        phone = params[:data][:values][:phone_numbers].first
        expect(phone[:country_code]).to eq("GB")
        {data: {id: {record_id: "123"}}}
      end

      described_class.create(
        first_name: "John",
        phone: "+44123456789",
        country_code: "GB"
      )
    end

    it "supports raw values for advanced use" do
      custom_values = {
        job_title: "CEO",  # Use a known simple field instead of custom_field
        name: [{full_name: "Jane Smith"}]
      }

      expect(described_class).to receive(:execute_request) do |_, _, params, _|
        # job_title is a SIMPLE_VALUE_ATTRIBUTE so it won't be wrapped
        expect(params[:data][:values]).to include(job_title: "CEO")
        expect(params[:data][:values][:name]).to eq([{full_name: "Jane Smith"}])
        {data: {id: {record_id: "123"}}}
      end

      described_class.create(values: custom_values)
    end
  end

  describe "#set_name" do
    let(:person) { described_class.new({id: {record_id: "123"}}) }

    it "sets name components" do
      person.set_name(first: "Jane", last: "Smith", middle: "Marie")

      expect(person[:name]).to eq([{
        first_name: "Jane",
        last_name: "Smith",
        middle_name: "Marie",
        full_name: "Jane Marie Smith"
      }])
    end

    it "generates full name automatically" do
      person.set_name(first: "John", last: "Doe")

      expect(person[:name].first[:full_name]).to eq("John Doe")
    end

    it "allows custom full name" do
      person.set_name(first: "John", last: "Doe", full: "Dr. John Doe")

      expect(person[:name].first[:full_name]).to eq("Dr. John Doe")
    end
  end

  describe "name accessors" do
    context "with array format (API response)" do
      let(:person) do
        described_class.new({
          id: {record_id: "123"},
          values: {
            name: [{
              first_name: "John",
              last_name: "Doe",
              full_name: "John Doe"
            }]
          }
        })
      end

      it "returns full name" do
        expect(person.full_name).to eq("John Doe")
      end

      it "returns first name" do
        expect(person.first_name).to eq("John")
      end

      it "returns last name" do
        expect(person.last_name).to eq("Doe")
      end
    end

    context "with hash format" do
      let(:person) do
        described_class.new({
          id: {record_id: "123"},
          values: {
            name: {
              first_name: "Jane",
              last_name: "Smith",
              full_name: "Jane Smith"
            }
          }
        })
      end

      it "returns full name" do
        expect(person.full_name).to eq("Jane Smith")
      end
    end

    context "without name" do
      let(:person) { described_class.new({id: {record_id: "123"}}) }

      it "returns nil for name accessors" do
        expect(person.full_name).to be_nil
        expect(person.first_name).to be_nil
        expect(person.last_name).to be_nil
      end
    end
  end

  describe "#add_email" do
    let(:person) { described_class.new({id: {record_id: "123"}}) }

    it "adds an email to empty list" do
      person.add_email("test@example.com")
      expect(person[:email_addresses]).to eq(["test@example.com"])
    end

    it "adds email to existing list" do
      person[:email_addresses] = ["first@example.com"]
      person.add_email("second@example.com")

      expect(person[:email_addresses]).to eq(["first@example.com", "second@example.com"])
    end

    it "prevents duplicate emails" do
      person[:email_addresses] = ["test@example.com"]
      person.add_email("test@example.com")

      expect(person[:email_addresses]).to eq(["test@example.com"])
    end
  end

  describe "#email" do
    it "returns primary email from array of strings" do
      person = described_class.new({
        values: {email_addresses: ["primary@example.com", "secondary@example.com"]}
      })

      expect(person.email).to eq("primary@example.com")
    end

    it "returns email from array of hashes (API response)" do
      person = described_class.new({
        values: {email_addresses: [{email_address: "test@example.com"}]}
      })

      expect(person.email).to eq("test@example.com")
    end

    it "returns nil when no emails" do
      person = described_class.new({})
      expect(person.email).to be_nil
    end
  end

  describe "#add_phone" do
    let(:person) { described_class.new({id: {record_id: "123"}}) }

    it "adds a phone number with default US country code" do
      person.add_phone("+12125551234")

      expect(person[:phone_numbers]).to eq([{
        original_phone_number: "+12125551234",
        country_code: "US"
      }])
    end

    it "adds phone with custom country code" do
      person.add_phone("+442012345678", country_code: "GB")

      expect(person[:phone_numbers].first[:country_code]).to eq("GB")
    end
  end

  describe "#phone" do
    it "returns primary phone from array of hashes" do
      person = described_class.new({
        values: {
          phone_numbers: [{
            original_phone_number: "+12125551234",
            country_code: "US"
          }]
        }
      })

      expect(person.phone).to eq("+12125551234")
    end

    it "returns nil when no phones" do
      person = described_class.new({})
      expect(person.phone).to be_nil
    end
  end

  describe "#company=" do
    let(:person) { described_class.new({id: {record_id: "123"}}) }

    it "accepts a Company instance" do
      company = Attio::Company.new({"id" => {"record_id" => "company-123"}})
      person.company = company

      expect(person[:company]).to eq([{
        target_object: "companies",
        target_record_id: "company-123"
      }])
    end

    it "accepts a company ID string" do
      person.company = "company-456"

      expect(person[:company]).to eq([{
        target_object: "companies",
        target_record_id: "company-456"
      }])
    end

    it "clears company when set to nil" do
      person.company = nil
      expect(person[:company]).to be_nil
    end

    it "raises error for invalid types" do
      expect { person.company = 123 }.to raise_error(ArgumentError)
    end
  end

  describe ".find_by_email" do
    it "searches for person by email" do
      allow(described_class).to receive(:list).with(
        params: {
          filter: {
            email_addresses: {"$contains": "test@example.com"}
          }
        }
      ).and_return([described_class.new({id: {record_id: "123"}})])

      person = described_class.find_by_email("test@example.com")
      expect(person).to be_a(described_class)
    end
  end

  describe ".find_by_name" do
    it "searches for person by name" do
      allow(described_class).to receive(:search).with("John Doe").and_return(
        [described_class.new({id: {record_id: "123"}})]
      )

      person = described_class.find_by_name("John Doe")
      expect(person).to be_a(described_class)
    end
  end
end
