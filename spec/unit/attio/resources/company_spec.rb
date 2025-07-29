# frozen_string_literal: true

require "spec_helper"

RSpec.describe Attio::Company do
  describe ".object_type" do
    it "returns 'companies'" do
      expect(described_class.object_type).to eq("companies")
    end
  end

  describe "class aliases" do
    it "provides Companies as an alias" do
      expect(Attio::Companies).to eq(described_class)
    end
  end

  describe ".create" do
    it "creates a company with simple name parameter" do
      allow(described_class).to receive(:execute_request).with(
        :POST,
        "objects/companies/records",
        {
          data: {
            values: {
              name: "Acme Corp"
            }
          }
        },
        {}
      ).and_return({"data" => {"id" => {"record_id" => "123"}, "values" => {"name" => "Acme Corp"}}})

      company = described_class.create(name: "Acme Corp")
      expect(company).to be_a(described_class)
      expect(company.name).to eq("Acme Corp")
    end

    it "creates a company with single domain" do
      expect(described_class).to receive(:execute_request) do |_, _, params, _|
        expect(params[:data][:values][:domains]).to eq(["acme.com"])
        {data: {id: {record_id: "123"}}}
      end

      described_class.create(name: "Acme", domain: "acme.com")
    end

    it "creates a company with multiple domains" do
      expect(described_class).to receive(:execute_request) do |_, _, params, _|
        expect(params[:data][:values][:domains]).to eq(["acme.com", "acme.org", "acme.io"])
        {data: {id: {record_id: "123"}}}
      end

      described_class.create(
        name: "Acme",
        domain: "acme.com",
        domains: ["acme.org", "acme.io"]
      )
    end

    it "creates a company with all attributes" do
      expect(described_class).to receive(:execute_request) do |_, _, params, _|
        values = params[:data][:values]
        expect(values[:name]).to eq("Acme Corp")
        expect(values[:domains]).to eq(["acme.com"])
        expect(values[:description]).to eq("Leading widget manufacturer")
        expect(values[:employee_count]).to eq("50")
        {data: {id: {record_id: "123"}}}
      end

      described_class.create(
        name: "Acme Corp",
        domain: "acme.com",
        description: "Leading widget manufacturer",
        employee_count: 50
      )
    end
  end

  describe "#name=" do
    let(:company) { described_class.new({id: {record_id: "123"}}) }

    it "sets the company name directly" do
      company.name = "New Name Inc"
      expect(company[:name]).to eq("New Name Inc")
    end
  end

  describe "#name" do
    it "returns the company name" do
      company = described_class.new({values: {name: "Test Company"}})
      expect(company.name).to eq("Test Company")
    end
  end

  describe "#add_domain" do
    let(:company) { described_class.new({id: {record_id: "123"}}) }

    it "adds a domain to empty list" do
      company.add_domain("example.com")
      expect(company[:domains]).to eq(["example.com"])
    end

    it "strips protocol from domain" do
      company.add_domain("https://example.com")
      expect(company[:domains]).to eq(["example.com"])
    end

    it "adds domain to existing list" do
      company[:domains] = ["first.com"]
      company.add_domain("second.com")
      expect(company[:domains]).to eq(["first.com", "second.com"])
    end

    it "prevents duplicate domains" do
      company[:domains] = ["example.com"]
      company.add_domain("example.com")
      expect(company[:domains]).to eq(["example.com"])
    end

    it "handles domains as hashes from API" do
      company[:domains] = [{domain: "first.com"}]
      company.add_domain("second.com")
      expect(company[:domains]).to include("second.com")
    end
  end

  describe "#domain" do
    it "returns primary domain from array of strings" do
      company = described_class.new({values: {domains: ["primary.com", "secondary.com"]}})
      expect(company.domain).to eq("primary.com")
    end

    it "returns domain from array of hashes (API response)" do
      company = described_class.new({values: {domains: [{domain: "test.com"}]}})
      expect(company.domain).to eq("test.com")
    end

    it "returns domain from hash format" do
      company = described_class.new({values: {domains: {domain: "single.com"}}})
      expect(company.domain).to eq("single.com")
    end

    it "returns nil when no domains" do
      company = described_class.new({})
      expect(company.domain).to be_nil
    end
  end

  describe "#domains_list" do
    it "returns all domains as strings" do
      company = described_class.new({
        values: {domains: [{domain: "first.com"}, {domain: "second.com"}]}
      })
      expect(company.domains_list).to eq(["first.com", "second.com"])
    end

    it "returns empty array when no domains" do
      company = described_class.new({})
      expect(company.domains_list).to eq([])
    end
  end

  describe "#description=" do
    let(:company) { described_class.new({id: {record_id: "123"}}) }

    it "sets the description" do
      company.description = "A great company"
      expect(company[:description]).to eq("A great company")
    end
  end

  describe "#employee_count=" do
    let(:company) { described_class.new({id: {record_id: "123"}}) }

    it "converts integer to string" do
      company.employee_count = 100
      expect(company[:employee_count]).to eq("100")
    end

    it "accepts string ranges" do
      company.employee_count = "50-100"
      expect(company[:employee_count]).to eq("50-100")
    end
  end

  describe "#add_team_member" do
    let(:company) { described_class.new({id: {record_id: "company-123"}}) }

    it "associates a Person instance with the company" do
      person = Attio::Person.new({id: {record_id: "person-123"}})
      expect(person).to receive(:company=).with(company)
      expect(person).to receive(:save)

      company.add_team_member(person)
    end

    it "associates a person by ID" do
      allow(Attio::Person).to receive(:retrieve).with("person-456").and_return(
        person = Attio::Person.new({id: {record_id: "person-456"}})
      )
      expect(person).to receive(:company=).with(company)
      expect(person).to receive(:save)

      company.add_team_member("person-456")
    end

    it "raises error for invalid types" do
      expect { company.add_team_member(123) }.to raise_error(ArgumentError)
    end
  end

  describe "#team_members" do
    let(:company) { described_class.new({"id" => {"record_id" => "company-123"}}) }

    it "lists people associated with the company" do
      expect(Attio::Person).to receive(:list).with(
        params: {
          filter: {
            company: {"$references": "company-123"}
          }
        }
      )

      company.team_members
    end
  end

  describe ".find_by_domain" do
    it "searches for company by domain" do
      allow(described_class).to receive(:list).with(
        filter: {
          domains: {
            domain: {
              "$eq": "example.com"
            }
          }
        }
      ).and_return([described_class.new({id: {record_id: "123"}})])

      company = described_class.find_by_domain("example.com")
      expect(company).to be_a(described_class)
    end

    it "strips protocol before searching" do
      allow(described_class).to receive(:list).with(
        filter: {
          domains: {
            domain: {
              "$eq": "example.com"
            }
          }
        }
      ).and_return([described_class.new({id: {record_id: "123"}})])

      result = described_class.find_by_domain("https://example.com")
      expect(result).to be_a(described_class)
    end
  end

  describe ".find_by_name" do
    it "searches for company by name" do
      allow(described_class).to receive(:search).with("Acme Corp").and_return(
        [described_class.new({id: {record_id: "123"}})]
      )

      company = described_class.find_by_name("Acme Corp")
      expect(company).to be_a(described_class)
    end
  end

  describe ".find_by_size" do
    it "finds companies with minimum employee count" do
      expect(described_class).to receive(:list).with(
        params: {
          filter: {
            employee_count: {"$gte": "100"}
          }
        }
      )

      described_class.find_by_size(100)
    end

    it "finds companies within employee count range" do
      expect(described_class).to receive(:list).with(
        params: {
          filter: {
            employee_count: {
              "$gte": "50",
              "$lte": "200"
            }
          }
        }
      )

      described_class.find_by_size(50, 200)
    end
  end
end
