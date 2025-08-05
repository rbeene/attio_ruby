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
      # Mock the API response with full structure
      response_data = {
        data: {
          id: {record_id: "123"},
          values: {
            name: [{
              active_from: Time.now.iso8601,
              active_until: nil,
              created_by_actor: {type: "api-token", id: "token_123"},
              first_name: "John",
              last_name: "Doe",
              full_name: "John Doe",
              attribute_type: "personal-name"
            }],
            email_addresses: [{
              active_from: Time.now.iso8601,
              active_until: nil,
              created_by_actor: {type: "api-token", id: "token_123"},
              email_address: "john@example.com",
              email_domain: "example.com",
              email_root_domain: "example.com",
              attribute_type: "email-address"
            }],
            phone_numbers: [{
              active_from: Time.now.iso8601,
              active_until: nil,
              created_by_actor: {type: "api-token", id: "token_123"},
              original_phone_number: "+1234567890",
              country_code: "US",
              phone_number: "+1 234 567 890",
              attribute_type: "phone-number"
            }],
            job_title: "Developer"
          }
        }
      }
      allow(described_class).to receive(:execute_request).and_return(response_data)

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

      # Define the response data that will be returned
      response_data = {
        data: {
          id: {record_id: "123"},
          values: {
            name: [{
              active_from: Time.now.iso8601,
              active_until: nil,
              created_by_actor: {type: "api-token", id: "token_123"},
              first_name: "John",
              last_name: "Doe",
              full_name: "John Doe",
              attribute_type: "personal-name"
            }],
            email_addresses: [{
              active_from: Time.now.iso8601,
              active_until: nil,
              created_by_actor: {type: "api-token", id: "token_123"},
              email_address: "john@example.com",
              email_domain: "example.com",
              email_root_domain: "example.com",
              attribute_type: "email-address"
            }],
            phone_numbers: [{
              active_from: Time.now.iso8601,
              active_until: nil,
              created_by_actor: {type: "api-token", id: "token_123"},
              original_phone_number: "+1234567890",
              country_code: "US",
              phone_number: "+1 234 567 890",
              attribute_type: "phone-number"
            }],
            job_title: "Developer"
          }
        }
      }

      allow(described_class).to receive(:execute_request).with(
        :POST,
        "objects/people/records",
        {data: {values: expected_values}},
        {}
      ).and_return(response_data)

      result = described_class.create(
        first_name: "John",
        last_name: "Doe",
        email: "john@example.com",
        phone: "+1234567890",
        job_title: "Developer"
      )
      expect(result).to be_a(described_class)
    end

    it "handles company association with Company instance" do
      company = Attio::Company.new({id: {record_id: "company-123"}})

      # Mock response with company association
      response_with_company = {
        data: {
          id: {record_id: "123"},
          values: {
            name: [{
              active_from: Time.now.iso8601,
              active_until: nil,
              created_by_actor: {type: "api-token", id: "token_123"},
              first_name: "John",
              last_name: "Doe",
              full_name: "John Doe",
              attribute_type: "personal-name"
            }],
            company: [{
              active_from: Time.now.iso8601,
              active_until: nil,
              created_by_actor: {type: "api-token", id: "token_123"},
              target_object: "companies",
              target_record_id: "company-123",
              attribute_type: "record-reference"
            }]
          }
        }
      }
      allow(described_class).to receive(:execute_request).and_return(response_with_company)

      result = described_class.create(
        first_name: "John",
        last_name: "Doe",
        company: company
      )
      expect(result).to be_a(described_class)
    end

    it "handles company association with string ID" do
      allow(described_class).to receive(:execute_request) do |_, _, params, _|
        expect(params[:data][:values][:company]).to eq([{
          target_object: "companies",
          target_record_id: "company-456"
        }])
        {
          data: {
            id: {record_id: "123"},
            values: {
              name: [{
                active_from: Time.now.iso8601,
                active_until: nil,
                created_by_actor: {type: "api-token", id: "token_123"},
                first_name: "Jane",
                last_name: "Smith",
                full_name: "Jane Smith",
                attribute_type: "personal-name"
              }],
              company: [{
                active_from: Time.now.iso8601,
                active_until: nil,
                created_by_actor: {type: "api-token", id: "token_123"},
                target_object: "companies",
                target_record_id: "company-456",
                attribute_type: "record-reference"
              }]
            }
          }
        }
      end

      result = described_class.create(
        first_name: "Jane",
        last_name: "Smith",
        company: "company-456"
      )
      expect(result).to be_a(described_class)
    end

    it "allows custom country code for phone" do
      expect(described_class).to receive(:execute_request) do |_, _, params, _|
        phone = params[:data][:values][:phone_numbers].first
        expect(phone[:country_code]).to eq("GB")
        {
          data: {
            id: {record_id: "123"},
            values: {
              name: [{
                active_from: Time.now.iso8601,
                active_until: nil,
                created_by_actor: {type: "api-token", id: "token_123"},
                first_name: "John",
                last_name: "",
                full_name: "John",
                attribute_type: "personal-name"
              }],
              phone_numbers: [{
                active_from: Time.now.iso8601,
                active_until: nil,
                created_by_actor: {type: "api-token", id: "token_123"},
                original_phone_number: "+44123456789",
                country_code: "GB",
                phone_number: "+44 123 456 789",
                attribute_type: "phone-number"
              }]
            }
          }
        }
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
        {
          data: {
            id: {record_id: "123"},
            values: {
              job_title: "CEO",
              name: [{full_name: "Jane Smith"}]
            }
          }
        }
      end

      described_class.create(values: custom_values)
    end

    it "creates a person with full_name parameter" do
      expect(described_class).to receive(:execute_request) do |_, _, params, _|
        expect(params[:data][:values][:name]).to eq([{
          first_name: "John",
          last_name: "Michael Doe Jr.",
          full_name: "John Michael Doe Jr."
        }])
        {
          data: {
            id: {record_id: "123"},
            values: {
              name: [{
                active_from: Time.now.iso8601,
                active_until: nil,
                created_by_actor: {type: "api-token", id: "token_123"},
                first_name: "John",
                last_name: "Michael Doe Jr.",
                full_name: "John Michael Doe Jr.",
                attribute_type: "personal-name"
              }],
              email_addresses: [{
                active_from: Time.now.iso8601,
                active_until: nil,
                created_by_actor: {type: "api-token", id: "token_123"},
                email_address: "john.doe@example.com",
                email_domain: "example.com",
                email_root_domain: "example.com",
                attribute_type: "email-address"
              }]
            }
          }
        }
      end

      result = described_class.create(
        full_name: "John Michael Doe Jr.",
        email: "john.doe@example.com"
      )
      expect(result).to be_a(described_class)
    end

    it "prioritizes full_name over computed name" do
      expect(described_class).to receive(:execute_request) do |_, _, params, _|
        expect(params[:data][:values][:name]).to eq([{
          first_name: "John",
          last_name: "Doe",
          full_name: "Dr. John Doe"
        }])
        {
          data: {
            id: {record_id: "123"},
            values: {
              name: [{
                active_from: Time.now.iso8601,
                active_until: nil,
                created_by_actor: {type: "api-token", id: "token_123"},
                first_name: "John",
                last_name: "Doe",
                full_name: "Dr. John Doe",
                attribute_type: "personal-name"
              }],
              email_addresses: [{
                active_from: Time.now.iso8601,
                active_until: nil,
                created_by_actor: {type: "api-token", id: "token_123"},
                email_address: "john@example.com",
                email_domain: "example.com",
                email_root_domain: "example.com",
                attribute_type: "email-address"
              }]
            }
          }
        }
      end

      result = described_class.create(
        first_name: "John",
        last_name: "Doe",
        full_name: "Dr. John Doe",
        email: "john@example.com"
      )
      expect(result).to be_a(described_class)
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

  describe "#name=" do
    let(:person) { described_class.new({id: {record_id: "123"}}) }

    it "accepts a hash with name components" do
      person.name = {first: "Jane", middle: "Marie", last: "Doe"}

      expect(person[:name]).to eq([{
        first_name: "Jane",
        middle_name: "Marie",
        last_name: "Doe",
        full_name: "Jane Marie Doe"
      }])
    end

    it "accepts a string as full name" do
      person.name = "John Michael Doe Jr."

      expect(person[:name]).to eq([{
        full_name: "John Michael Doe Jr."
      }])
    end

    it "raises error for invalid input" do
      expect { person.name = 123 }.to raise_error(ArgumentError, "Name must be a Hash or String")
    end
  end

  describe "name accessors" do
    context "with array format (API response)" do
      let(:person) do
        described_class.new({
          id: {record_id: "123"},
          values: {
            name: [{
              active_from: Time.now.iso8601,
              active_until: nil,
              created_by_actor: {type: "api-token", id: "token_123"},
              first_name: "John",
              last_name: "Doe",
              full_name: "John Doe",
              attribute_type: "personal-name"
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

    context "with array format using string keys" do
      let(:person) do
        described_class.new({
          id: {record_id: "123"},
          values: {
            name: [{
              "first_name" => "Alice",
              "last_name" => "Johnson",
              "full_name" => "Alice Johnson"
            }]
          }
        })
      end

      it "returns full name with string keys" do
        expect(person.full_name).to eq("Alice Johnson")
      end

      it "returns first name with string keys" do
        expect(person.first_name).to eq("Alice")
      end

      it "returns last name with string keys" do
        expect(person.last_name).to eq("Johnson")
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

      it "returns first name" do
        expect(person.first_name).to eq("Jane")
      end

      it "returns last name" do
        expect(person.last_name).to eq("Smith")
      end
    end

    context "with hash format using string keys" do
      let(:person) do
        described_class.new({
          id: {record_id: "123"},
          values: {
            name: {
              "first_name" => "Bob",
              "last_name" => "Wilson",
              "full_name" => "Bob Wilson"
            }
          }
        })
      end

      it "returns full name with string keys" do
        expect(person.full_name).to eq("Bob Wilson")
      end

      it "returns first name with string keys" do
        expect(person.first_name).to eq("Bob")
      end

      it "returns last name with string keys" do
        expect(person.last_name).to eq("Wilson")
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

    it "returns email from array of hashes with string keys" do
      person = described_class.new({
        values: {email_addresses: [{"email_address" => "string-key@example.com"}]}
      })

      expect(person.email).to eq("string-key@example.com")
    end

    it "returns email from hash format" do
      person = described_class.new({
        values: {email_addresses: {email_address: "hash@example.com"}}
      })

      expect(person.email).to eq("hash@example.com")
    end

    it "returns email from hash format with string keys" do
      person = described_class.new({
        values: {email_addresses: {"email_address" => "hash-string@example.com"}}
      })

      expect(person.email).to eq("hash-string@example.com")
    end

    it "converts non-standard format to string" do
      person = described_class.new({
        values: {email_addresses: "direct@example.com"}
      })

      expect(person.email).to eq("direct@example.com")
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

    it "returns phone from array of hashes with string keys" do
      person = described_class.new({
        values: {
          phone_numbers: [{
            "original_phone_number" => "+44123456789",
            "country_code" => "GB"
          }]
        }
      })

      expect(person.phone).to eq("+44123456789")
    end

    it "returns phone from array of non-hash values" do
      person = described_class.new({
        values: {
          phone_numbers: ["+15551234567", "+15559876543"]
        }
      })

      expect(person.phone).to eq("+15551234567")
    end

    it "returns phone from hash format" do
      person = described_class.new({
        values: {
          phone_numbers: {
            original_phone_number: "+33123456789",
            country_code: "FR"
          }
        }
      })

      expect(person.phone).to eq("+33123456789")
    end

    it "returns phone from hash format with string keys" do
      person = described_class.new({
        values: {
          phone_numbers: {
            "original_phone_number" => "+49123456789",
            "country_code" => "DE"
          }
        }
      })

      expect(person.phone).to eq("+49123456789")
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

  describe ".find_by with email" do
    it "searches for person by email using Rails-style syntax" do
      allow(described_class).to receive(:list).with(
        params: {
          filter: {
            email_addresses: {
              email_address: {
                "$eq": "test@example.com"
              }
            }
          }
        }
      ).and_return([described_class.new({id: {record_id: "123"}})])

      person = described_class.find_by(email: "test@example.com")
      expect(person).to be_a(described_class)
    end
  end

  describe ".find_by with name" do
    it "searches for person by name using Rails-style syntax" do
      # Name searches now use filters with $or across name fields
      allow(described_class).to receive(:list).with(
        params: {
          filter: {
            "$or": [
              {name: {first_name: {"$contains": "John Doe"}}},
              {name: {last_name: {"$contains": "John Doe"}}},
              {name: {full_name: {"$contains": "John Doe"}}}
            ]
          }
        }
      ).and_return([described_class.new({id: {record_id: "123"}})])
      
      person = described_class.find_by(name: "John Doe")
      expect(person).to be_a(described_class)
    end
  end

end
