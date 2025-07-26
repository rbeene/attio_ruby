# frozen_string_literal: true

RSpec.describe Attio::Services::PersonService do
  let(:service) { described_class.new }
  let(:connection_manager) { instance_double(Attio::Util::ConnectionManager) }

  before do
    Attio.configure { |c| c.api_key = "test_key" }
    allow(Attio).to receive(:connection_manager).and_return(connection_manager)
  end

  describe "#find_by_email" do
    let(:response) do
      {
        status: 200,
        headers: {},
        body: JSON.generate({
          data: [{
            id: "person-123",
            values: {
              email_addresses: [{value: "john@example.com"}],
              name: [{value: "John Doe"}]
            }
          }],
          pagination: {}
        })
      }
    end

    it "finds a person by email" do
      allow(connection_manager).to receive(:execute).and_return(response)

      person = service.find_by_email("john@example.com")

      expect(person).to be_a(Attio::Record)
      expect(person.id).to eq("person-123")
    end

    it "returns nil when not found" do
      empty_response = response.dup
      empty_response[:body] = JSON.generate({data: [], pagination: {}})
      allow(connection_manager).to receive(:execute).and_return(empty_response)

      person = service.find_by_email("notfound@example.com")

      expect(person).to be_nil
    end
  end

  describe "#create" do
    let(:response) do
      {
        status: 200,
        headers: {},
        body: JSON.generate({
          data: {
            id: "person-new",
            values: {
              name: [{value: "Jane Doe"}],
              email_addresses: [{value: "jane@example.com"}]
            }
          }
        })
      }
    end

    it "creates a person with basic attributes" do
      allow(connection_manager).to receive(:execute).and_return(response)

      person = service.create(
        name: "Jane Doe",
        email: "jane@example.com",
        phone: "+1234567890",
        title: "Developer"
      )

      expect(person).to be_a(Attio::Record)
      expect(person.id).to eq("person-new")
    end

    it "handles company reference by ID" do
      allow(connection_manager).to receive(:execute) do |request|
        values = request[:params][:data][:values]
        expect(values[:company]).to eq([{
          target_object: "companies",
          target_record: "550e8400-e29b-41d4-a716-446655440000"
        }])
        response
      end

      service.create(
        name: "Jane Doe",
        company: "550e8400-e29b-41d4-a716-446655440000"
      )
    end

    it "handles company by name" do
      # The PersonService will create a CompanyService and call find_or_create_by_name
      # We'll mock that method directly instead of mocking the HTTP response
      company_double = double(id: "company-123")
      allow_any_instance_of(Attio::Services::CompanyService).to receive(:find_or_create_by_name)
        .with("Acme Corp")
        .and_return(company_double)

      # Now mock the response for creating the person
      allow(connection_manager).to receive(:execute).and_return(response)

      person = service.create(name: "Jane Doe", company: "Acme Corp")
      expect(person).to be_a(Attio::Record)
    end
  end

  describe "#merge" do
    let(:primary_person) { double(Attio::Record, :id => "person-1", :[] => nil, :[]= => nil, :save => true) }
    let(:duplicate1) { double(Attio::Record, id: "person-2", attributes: {}, destroy: true) }
    let(:duplicate2) { double(Attio::Record, id: "person-3", attributes: {}, destroy: true) }

    it "merges duplicate people into primary" do
      allow(Attio::Record).to receive(:retrieve).with(object: "people", record_id: "person-1")
        .and_return(primary_person)
      allow(service).to receive(:find_by_ids).with(["person-2", "person-3"])
        .and_return([duplicate1, duplicate2])

      result = service.merge("person-1", ["person-2", "person-3"])

      expect(result).to eq(primary_person)
      expect(duplicate1).to have_received(:destroy)
      expect(duplicate2).to have_received(:destroy)
    end
  end

  describe "#import_from_csv" do
    let(:csv_data) do
      [
        {"Name" => "John Doe", "Email" => "john@example.com", "Phone" => "123-456-7890"},
        {"Name" => "Jane Smith", "Email" => "jane@example.com", "Phone" => "098-765-4321"}
      ]
    end

    let(:mapping) do
      {
        "Name" => :name,
        "Email" => :email_addresses,
        "Phone" => :phone_numbers
      }
    end

    it "imports people from CSV data" do
      expect(service).to receive(:import).with(
        [
          {values: {
            name: [{value: "John Doe"}],
            email_addresses: [{value: "john@example.com"}],
            phone_numbers: [{value: "123-456-7890"}]
          }},
          {values: {
            name: [{value: "Jane Smith"}],
            email_addresses: [{value: "jane@example.com"}],
            phone_numbers: [{value: "098-765-4321"}]
          }}
        ],
        on_error: :continue
      )

      service.import_from_csv(csv_data, mapping: mapping)
    end

    it "skips empty values" do
      csv_data_with_empty = [
        {"Name" => "John Doe", "Email" => "", "Phone" => nil}
      ]

      expect(service).to receive(:import).with(
        [{values: {name: [{value: "John Doe"}]}}],
        on_error: :continue
      )

      service.import_from_csv(csv_data_with_empty, mapping: mapping)
    end
  end

  describe "#add_note" do
    it "adds a note to a person" do
      expect(Attio::Note).to receive(:create).with(
        parent_object: "people",
        parent_record_id: "person-123",
        content: "Called about project",
        format: "plaintext"
      )

      service.add_note("person-123", "Called about project")
    end
  end

  describe "#lists" do
    let(:person) { double(Attio::Record, lists: []) }

    it "gets lists for a person" do
      allow(Attio::Record).to receive(:retrieve).with(object: "people", record_id: "person-123")
        .and_return(person)

      lists = service.lists("person-123")

      expect(lists).to eq([])
    end
  end
end
