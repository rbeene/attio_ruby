# frozen_string_literal: true

RSpec.shared_examples "a listable resource" do
  let(:connection_manager) { instance_double(Attio::Util::ConnectionManager) }
  let(:list_response) do
    {
      status: 200,
      headers: {},
      body: JSON.generate({
        data: [
          {id: "1", name: "Item 1"},
          {id: "2", name: "Item 2"}
        ],
        pagination: {
          has_next_page: false,
          total_count: 2
        }
      })
    }
  end

  before do
    allow(Attio::Util::ConnectionManager).to receive(:new).and_return(connection_manager)
    allow(connection_manager).to receive(:execute).and_return(list_response)
  end

  it "returns a ListObject" do
    result = described_class.list
    expect(result).to be_a(Attio::APIOperations::List::ListObject)
  end

  it "contains the correct number of items" do
    result = described_class.list
    expect(result.count).to eq(2)
  end

  it "supports pagination" do
    result = described_class.list
    expect(result.has_next_page?).to be false
    expect(result.total_count).to eq(2)
  end

  it "supports auto-pagination" do
    items = []
    described_class.list.auto_paging_each { |item| items << item }
    expect(items.size).to eq(2)
  end
end

RSpec.shared_examples "a retrievable resource" do
  let(:connection_manager) { instance_double(Attio::Util::ConnectionManager) }
  let(:retrieve_response) do
    {
      status: 200,
      headers: {},
      body: JSON.generate({
        id: "123",
        name: "Test Item"
      })
    }
  end

  before do
    allow(Attio::Util::ConnectionManager).to receive(:new).and_return(connection_manager)
    allow(connection_manager).to receive(:execute).and_return(retrieve_response)
  end

  it "retrieves a single resource" do
    result = described_class.retrieve("123")
    expect(result).to be_a(described_class)
    expect(result.id).to eq("123")
  end

  it "raises error without ID" do
    expect do
      described_class.retrieve(nil)
    end.to raise_error(ArgumentError, "ID is required")
  end
end

RSpec.shared_examples "a creatable resource" do
  let(:connection_manager) { instance_double(Attio::Util::ConnectionManager) }
  let(:create_response) do
    {
      status: 200,
      headers: {},
      body: JSON.generate({
        id: "new-123",
        name: "New Item"
      })
    }
  end

  before do
    allow(Attio::Util::ConnectionManager).to receive(:new).and_return(connection_manager)
    allow(connection_manager).to receive(:execute).and_return(create_response)
  end

  it "creates a new resource" do
    result = described_class.create(name: "New Item")
    expect(result).to be_a(described_class)
    expect(result.id).to eq("new-123")
  end

  it "sends POST request" do
    allow(connection_manager).to receive(:execute) do |request|
      expect(request[:method]).to eq(:POST)
      create_response
    end

    described_class.create(name: "New Item")
  end
end

RSpec.shared_examples "an updatable resource" do
  let(:resource) { described_class.new({id: "123", name: "Original"}) }
  let(:connection_manager) { instance_double(Attio::Util::ConnectionManager) }
  let(:update_response) do
    {
      status: 200,
      headers: {},
      body: JSON.generate({
        id: "123",
        name: "Updated"
      })
    }
  end

  before do
    allow(Attio::Util::ConnectionManager).to receive(:new).and_return(connection_manager)
    allow(connection_manager).to receive(:execute).and_return(update_response)
  end

  it "updates the resource" do
    resource.name = "Updated"
    result = resource.save

    expect(result).to eq(resource)
    expect(resource.changed?).to be false
  end

  it "raises error without ID" do
    resource_without_id = described_class.new({})

    expect do
      resource_without_id.save
    end.to raise_error(Attio::Errors::InvalidRequestError)
  end
end

RSpec.shared_examples "a deletable resource" do
  let(:connection_manager) { instance_double(Attio::Util::ConnectionManager) }
  let(:delete_response) do
    {
      status: 204,
      headers: {},
      body: ""
    }
  end

  before do
    allow(Attio::Util::ConnectionManager).to receive(:new).and_return(connection_manager)
    allow(connection_manager).to receive(:execute).and_return(delete_response)
  end

  context "when using class method" do
    it "deletes by ID" do
      result = described_class.delete("123")
      expect(result).to be true
    end

    it "sends DELETE request" do
      allow(connection_manager).to receive(:execute) do |request|
        expect(request[:method]).to eq(:DELETE)
        delete_response
      end

      described_class.delete("123")
    end
  end

  context "when using instance method" do
    let(:resource) { described_class.new({id: "123"}) }

    it "deletes the resource" do
      result = resource.destroy
      expect(result).to be true
      expect(resource).to be_frozen
    end
  end
end
