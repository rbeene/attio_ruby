# frozen_string_literal: true

RSpec.describe Attio::Record do
  let(:api_key) { "test_api_key" }
  let(:connection_manager) { instance_double(Attio::Util::ConnectionManager) }
  
  before do
    Attio.configure { |c| c.api_key = api_key }
    allow(Attio::Util::ConnectionManager).to receive(:new).and_return(connection_manager)
  end

  describe ".list" do
    let(:response) do
      {
        status: 200,
        headers: {},
        body: JSON.generate({
          data: [
            { id: "123", values: { name: [{ value: "John" }] } },
            { id: "456", values: { name: [{ value: "Jane" }] } }
          ],
          pagination: { has_next_page: false }
        })
      }
    end

    it "lists records for an object" do
      allow(connection_manager).to receive(:execute).and_return(response)
      
      records = described_class.list(object: "people")
      
      expect(records).to be_a(Attio::APIOperations::List::ListObject)
      expect(records.count).to eq(2)
      expect(records.first.id).to eq("123")
    end

    it "supports filtering" do
      allow(connection_manager).to receive(:execute) do |request|
        expect(request[:params][:filter]).to eq({ status: "active" })
        response
      end
      
      described_class.list(object: "people", params: { filter: { status: "active" } })
    end

    it "supports sorting" do
      allow(connection_manager).to receive(:execute) do |request|
        expect(request[:params][:sort]).to eq({ field: "created_at", direction: "desc" })
        response
      end
      
      described_class.list(object: "people", params: { sort: "created_at:desc" })
    end

    it "raises error without object identifier" do
      expect do
        described_class.list(object: nil)
      end.to raise_error(ArgumentError, "Object identifier is required")
    end
  end

  describe ".create" do
    let(:response) do
      {
        status: 200,
        headers: {},
        body: JSON.generate({
          data: {
            id: "new-123",
            object_id: "obj-123",
            values: { name: [{ value: "John" }] }
          }
        })
      }
    end

    it "creates a new record" do
      allow(connection_manager).to receive(:execute).and_return(response)
      
      record = described_class.create(
        object: "people",
        values: { name: "John" }
      )
      
      expect(record).to be_a(described_class)
      expect(record.id).to eq("new-123")
      expect(record[:name]).to eq("John")
    end

    it "normalizes scalar values" do
      allow(connection_manager).to receive(:execute) do |request|
        expect(request[:params][:data][:values]).to eq({
          name: { value: "John" },
          age: { value: 30 }
        })
        response
      end
      
      described_class.create(
        object: "people",
        values: { name: "John", age: 30 }
      )
    end

    it "handles array values" do
      allow(connection_manager).to receive(:execute) do |request|
        expect(request[:params][:data][:values][:tags]).to eq([
          { value: "tag1" },
          { value: "tag2" }
        ])
        response
      end
      
      described_class.create(
        object: "people",
        values: { tags: ["tag1", "tag2"] }
      )
    end
  end

  describe ".create_batch" do
    let(:response) do
      {
        status: 200,
        headers: {},
        body: JSON.generate({
          data: [
            { id: "123", values: { name: [{ value: "John" }] } },
            { id: "456", values: { name: [{ value: "Jane" }] } }
          ]
        })
      }
    end

    it "creates multiple records" do
      allow(connection_manager).to receive(:execute).and_return(response)
      
      records = described_class.create_batch(
        object: "people",
        records: [
          { values: { name: "John" } },
          { values: { name: "Jane" } }
        ]
      )
      
      expect(records).to be_an(Array)
      expect(records.size).to eq(2)
      expect(records.first).to be_a(described_class)
    end

    it "validates records is an array" do
      expect do
        described_class.create_batch(object: "people", records: "not-array")
      end.to raise_error(ArgumentError, "Records must be an array")
    end
  end

  describe "#save" do
    let(:record) do
      described_class.new(
        { id: "123", values: { name: [{ value: "John" }] } },
        { api_key: api_key }
      )
    end

    let(:response) do
      {
        status: 200,
        headers: {},
        body: JSON.generate({
          data: {
            id: "123",
            values: { name: [{ value: "John Updated" }] }
          }
        })
      }
    end

    it "updates the record" do
      allow(connection_manager).to receive(:execute).and_return(response)
      
      record[:name] = "John Updated"
      saved = record.save
      
      expect(saved).to eq(record)
      expect(record.changed?).to be false
    end

    it "only sends changed attributes" do
      allow(connection_manager).to receive(:execute) do |request|
        expect(request[:params][:data][:values].keys).to eq([:email])
        response
      end
      
      record[:email] = "john@example.com"
      record.save
    end

    it "raises error without an ID" do
      record_without_id = described_class.new({})
      
      expect do
        record_without_id.save
      end.to raise_error(Attio::Errors::InvalidRequestError, "Cannot update a record without an ID")
    end
  end

  describe "#lists" do
    let(:record) do
      described_class.new({ id: "123" }, { api_key: api_key })
    end

    it "returns lists containing the record" do
      expect(Attio::List).to receive(:list).with(record_id: "123").and_return([])
      
      record.lists
    end
  end

  describe "#add_to_list" do
    let(:record) do
      described_class.new({ id: "123" }, { api_key: api_key })
    end

    it "adds the record to a list" do
      expect(Attio::ListEntry).to receive(:create).with(list_id: "list-456", record_id: "123")
      
      record.add_to_list("list-456")
    end
  end

  describe "attribute access" do
    let(:record) do
      described_class.new({
        id: "123",
        values: {
          name: [{ value: "John Doe" }],
          email: [{ value: "john@example.com" }],
          tags: [{ value: "tag1" }, { value: "tag2" }]
        }
      })
    end

    it "extracts values from Attio format" do
      expect(record[:name]).to eq("John Doe")
      expect(record[:email]).to eq("john@example.com")
      expect(record[:tags]).to eq(["tag1", "tag2"])
    end

    it "tracks changes" do
      record[:name] = "Jane Doe"
      
      expect(record.changed?).to be true
      expect(record.changed).to include("name")
      expect(record.changes["name"]).to eq(["John Doe", "Jane Doe"])
    end
  end
end