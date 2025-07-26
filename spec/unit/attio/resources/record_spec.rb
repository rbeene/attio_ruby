# frozen_string_literal: true

RSpec.describe Attio::Record do
  let(:api_key) { "test_api_key" }
  let(:client) { instance_double(Attio::Client) }

  before do
    Attio.configure { |c| c.api_key = api_key }
    allow(Attio).to receive(:client).and_return(client)
  end

  describe ".list" do
    let(:response_data) do
      {
        data: [
          {id: "123", values: {name: [{value: "John"}]}},
          {id: "456", values: {name: [{value: "Jane"}]}}
        ]
      }
    end

    it "lists records for an object" do
      allow(client).to receive(:get).with("/objects/people/records", {}).and_return(response_data)

      records = described_class.list(object: "people")
      
      expect(records).to be_a(Attio::APIResource::ListObject)
      expect(records.count).to eq(2)
      expect(records.first.id).to eq("123")
    end

    it "supports filtering" do
      allow(client).to receive(:get).with("/objects/people/records", {filter: {name: "John"}}).and_return(response_data)

      records = described_class.list(object: "people", filter: {name: "John"})
      expect(records.count).to eq(2)
    end

    it "supports sorting" do
      allow(client).to receive(:get).with("/objects/people/records", {sort: {name: "asc"}}).and_return(response_data)

      records = described_class.list(object: "people", sort: {name: "asc"})
      expect(records.count).to eq(2)
    end

    it "raises error without object identifier" do
      expect {
        described_class.list
      }.to raise_error(ArgumentError, "object is required")
    end
  end

  describe ".create" do
    let(:values) { {name: [{value: "John Doe"}], email: [{value: "john@example.com"}]} }
    let(:response_data) { {id: "rec_123", values: values} }

    it "creates a new record" do
      allow(client).to receive(:post).with("/objects/people/records", {values: values}).and_return(response_data)

      record = described_class.create(object: "people", values: values)
      
      expect(record).to be_a(described_class)
      expect(record.id).to eq("rec_123")
    end

    it "normalizes scalar values" do
      scalar_values = {name: "John Doe"}
      normalized_values = {name: [{value: "John Doe"}]}
      
      allow(client).to receive(:post).with("/objects/people/records", {values: normalized_values}).and_return(response_data)

      record = described_class.create(object: "people", values: scalar_values)
      expect(record.id).to eq("rec_123")
    end

    it "handles array values" do
      array_values = {tags: ["tag1", "tag2"]}
      normalized_values = {tags: [{value: "tag1"}, {value: "tag2"}]}
      
      allow(client).to receive(:post).with("/objects/people/records", {values: normalized_values}).and_return(response_data)

      record = described_class.create(object: "people", values: array_values)
      expect(record.id).to eq("rec_123")
    end
  end

  describe ".create_batch" do
    let(:records_data) do
      [
        {values: {name: [{value: "John"}]}},
        {values: {name: [{value: "Jane"}]}}
      ]
    end
    let(:response_data) do
      {
        data: [
          {id: "rec_1", values: {name: [{value: "John"}]}},
          {id: "rec_2", values: {name: [{value: "Jane"}]}}
        ]
      }
    end

    it "creates multiple records" do
      allow(client).to receive(:post).with("/objects/people/records/batch", {records: records_data}).and_return(response_data)

      records = described_class.create_batch(object: "people", records: records_data)
      
      expect(records).to be_an(Array)
      expect(records.count).to eq(2)
      expect(records.first.id).to eq("rec_1")
    end

    it "validates records is an array" do
      expect {
        described_class.create_batch(object: "people", records: "not an array")
      }.to raise_error(ArgumentError, "records must be an array")
    end
  end

  describe "#save" do
    let(:record) { described_class.new({id: "rec_123", object_api_slug: "people"}) }
    let(:record_without_id) { described_class.new({}) }

    it "updates the record" do
      record[:name] = [{value: "Updated Name"}]
      
      allow(client).to receive(:patch).with("/objects/people/records/rec_123", {values: {name: [{value: "Updated Name"}]}})
        .and_return({id: "rec_123", values: {name: [{value: "Updated Name"}]}})

      result = record.save
      
      expect(result).to eq(record)
      expect(record.changed?).to be false
    end

    it "only sends changed attributes" do
      record[:name] = [{value: "New Name"}]
      # Don't change email, so it shouldn't be sent
      
      allow(client).to receive(:patch).with("/objects/people/records/rec_123", {values: {name: [{value: "New Name"}]}})
        .and_return({id: "rec_123", values: {name: [{value: "New Name"}]}})

      record.save
    end

    it "raises error without an ID" do
      expect do
        record_without_id.save
      end.to raise_error(Attio::InvalidRequestError, "Cannot update a record without an ID")
    end
  end

  describe "#lists" do
    let(:record) { described_class.new({id: "rec_123", object_api_slug: "people"}) }
    let(:lists_response) do
      {
        data: [
          {id: "list_1", name: "VIP Customers"},
          {id: "list_2", name: "Newsletter"}
        ]
      }
    end

    it "returns lists containing the record" do
      allow(client).to receive(:get).with("/lists", {record_id: "rec_123"}).and_return(lists_response)

      lists = record.lists
      
      expect(lists).to be_an(Array)
      expect(lists.count).to eq(2)
      expect(lists.first["name"]).to eq("VIP Customers")
    end
  end

  describe "#add_to_list" do
    let(:record) { described_class.new({id: "rec_123", object_api_slug: "people"}) }
    let(:entry_response) { {id: "entry_123", list_id: "list_456", record_id: "rec_123"} }

    it "adds the record to a list" do
      allow(client).to receive(:post).with("/lists/list_456/entries", {record_id: "rec_123"})
        .and_return(entry_response)

      entry = record.add_to_list("list_456")
      
      expect(entry["id"]).to eq("entry_123")
    end
  end

  describe "attribute access" do
    let(:record) do
      described_class.new({
        id: "rec_123",
        values: {
          name: [{value: "John Doe"}],
          email: [{value: "john@example.com"}],
          tags: [{value: "tag1"}, {value: "tag2"}]
        }
      })
    end

    it "extracts values from Attio format" do
      expect(record.name).to eq([{value: "John Doe"}])
      expect(record.email).to eq([{value: "john@example.com"}])
      expect(record.tags).to eq([{value: "tag1"}, {value: "tag2"}])
    end

    it "tracks changes" do
      expect(record.changed?).to be false
      
      record.name = [{value: "Jane Doe"}]
      
      expect(record.changed?).to be true
      expect(record.changed).to include("name")
      expect(record.changes["name"]).to eq([[{value: "John Doe"}], [{value: "Jane Doe"}]])
    end
  end
end