# frozen_string_literal: true

RSpec.shared_examples "a listable resource" do
  let(:list_response) do
    {
      data: [
        {id: "1", name: "Item 1"},
        {id: "2", name: "Item 2"}
      ],
      has_more: false,
      cursor: nil
    }
  end

  before do
    stub_request(:get, "https://api.attio.com#{described_class.resource_path}")
      .with(headers: {"Authorization" => "Bearer test_api_key"})
      .to_return(
        status: 200,
        body: JSON.generate(list_response),
        headers: {"Content-Type" => "application/json"}
      )
  end

  it "returns a ListObject" do
    result = described_class.list
    expect(result).to be_a(Attio::APIResource::ListObject)
  end

  it "contains the correct number of items" do
    result = described_class.list
    expect(result.count).to eq(2)
  end

  it "supports pagination" do
    result = described_class.list
    expect(result.has_more?).to be false
  end

  it "supports auto-pagination" do
    items = []
    described_class.list.auto_paging_each { |item| items << item }
    expect(items.size).to eq(2)
  end
end

RSpec.shared_examples "a retrievable resource" do
  let(:retrieve_response) do
    {
      data: {
        id: "123",
        name: "Test Item"
      }
    }
  end

  before do
    stub_request(:get, "https://api.attio.com#{described_class.resource_path}/123")
      .with(headers: {"Authorization" => "Bearer test_api_key"})
      .to_return(
        status: 200,
        body: JSON.generate(retrieve_response),
        headers: {"Content-Type" => "application/json"}
      )
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
  let(:create_response) do
    {
      data: {
        id: "new-123",
        name: "New Item"
      }
    }
  end

  before do
    stub_request(:post, "https://api.attio.com#{described_class.resource_path}")
      .with(
        headers: {"Authorization" => "Bearer test_api_key"},
        body: {name: "New Item"}.to_json
      )
      .to_return(
        status: 200,
        body: JSON.generate(create_response),
        headers: {"Content-Type" => "application/json"}
      )
  end

  it "creates a new resource" do
    result = described_class.create(name: "New Item")
    expect(result).to be_a(described_class)
    expect(result.id).to eq("new-123")
  end

  it "sends POST request" do
    described_class.create(name: "New Item")
    expect(WebMock).to have_requested(:post, "https://api.attio.com#{described_class.resource_path}")
  end
end

RSpec.shared_examples "an updatable resource" do
  let(:resource) { described_class.new({id: "123", name: "Original"}) }
  let(:update_response) do
    {
      data: {
        id: "123",
        name: "Updated"
      }
    }
  end

  before do
    stub_request(:patch, "https://api.attio.com#{described_class.resource_path}/123")
      .with(
        headers: {"Authorization" => "Bearer test_api_key"},
        body: {name: "Updated"}.to_json
      )
      .to_return(
        status: 200,
        body: JSON.generate(update_response),
        headers: {"Content-Type" => "application/json"}
      )
  end

  it "updates the resource" do
    resource.name = "Updated"
    result = resource.save

    expect(result).to be_a(described_class)
    expect(resource.changed?).to be false
  end

  it "raises error without ID" do
    resource_without_id = described_class.new({})

    expect do
      resource_without_id.save
    end.to raise_error(Attio::InvalidRequestError)
  end
end

RSpec.shared_examples "a deletable resource" do
  before do
    stub_request(:delete, "https://api.attio.com#{described_class.resource_path}/123")
      .with(headers: {"Authorization" => "Bearer test_api_key"})
      .to_return(status: 204, body: "")
  end

  context "when using class method" do
    it "deletes by ID" do
      result = described_class.delete("123")
      expect(result).to be true
    end

    it "sends DELETE request" do
      described_class.delete("123")
      expect(WebMock).to have_requested(:delete, "https://api.attio.com#{described_class.resource_path}/123")
    end
  end

  context "when using instance method" do
    let(:resource) { described_class.new({id: "123"}) }

    it "deletes the resource" do
      result = resource.destroy
      expect(result).to be true
    end
  end
end
