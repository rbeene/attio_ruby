# frozen_string_literal: true

require "spec_helper"

RSpec.describe Attio::List do
  let(:list_attributes) do
    {
      id: {list_id: "list_123"},
      api_slug: "contacts",
      name: "Contacts",
      object_id: "obj_123",
      object_api_slug: "people",
      created_by_actor: {
        type: "user",
        id: "usr_123"
      },
      workspace_id: "ws_123",
      workspace_access: "collaborative",
      parent_object: ["people"],
      filters: []
    }
  end

  describe "#initialize" do
    it "sets attributes correctly" do
      list = described_class.new(list_attributes)

      expect(list.api_slug).to eq("contacts")
      expect(list.name).to eq("Contacts")
      expect(list.attio_object_id).to eq("obj_123")
      expect(list.object_api_slug).to eq("people")
      expect(list.created_by_actor).to eq({type: "user", id: "usr_123"})
      expect(list.workspace_id).to eq("ws_123")
      expect(list.workspace_access).to eq("collaborative")
      expect(list.filters).to eq([])
    end

    it "handles string keys" do
      string_attrs = {
        "id" => {"list_id" => "list_456"},
        "api_slug" => "companies",
        "name" => "Companies",
        "object_id" => "obj_456"
      }

      list = described_class.new(string_attrs)
      expect(list.api_slug).to eq("companies")
      expect(list.name).to eq("Companies")
    end

    it "handles parent_object vs object attribute" do
      # When parent_object is provided
      list = described_class.new(list_attributes)
      expect(list.object).to eq("people")

      # When object is provided instead
      attrs_with_object = list_attributes.dup
      attrs_with_object.delete(:parent_object)
      attrs_with_object[:object] = ["companies"]

      list2 = described_class.new(attrs_with_object)
      expect(list2.object).to eq("companies")
    end
  end

  describe "#object" do
    it "returns the first element when parent_object is an array" do
      list = described_class.new(list_attributes)
      expect(list.object).to eq("people")
    end

    it "returns the value when parent_object is not an array" do
      attrs = list_attributes.merge(parent_object: "companies")
      list = described_class.new(attrs)
      expect(list.object).to eq("companies")
    end

    it "returns nil when parent_object is nil" do
      attrs = list_attributes.merge(parent_object: nil)
      list = described_class.new(attrs)
      expect(list.object).to be_nil
    end
  end

  describe ".resource_path" do
    it "returns the correct path" do
      expect(described_class.resource_path).to eq("lists")
    end
  end

  describe "#resource_path" do
    it "returns the correct path for a persisted list" do
      list = described_class.new(list_attributes)
      expect(list.resource_path).to eq("lists/list_123")
    end

    it "extracts list_id from nested hash" do
      list = described_class.new(id: {list_id: "list_789"})
      expect(list.resource_path).to eq("lists/list_789")
    end

    it "handles simple ID format" do
      list = described_class.new(id: "list_simple")
      expect(list.resource_path).to eq("lists/list_simple")
    end

    it "raises error for unpersisted list" do
      list = described_class.new({})
      expect { list.resource_path }.to raise_error(
        Attio::InvalidRequestError,
        "Cannot generate path without an ID"
      )
    end
  end

  describe "#id_for_path" do
    it "extracts list_id from nested hash" do
      list = described_class.new(list_attributes)
      expect(list.id).to eq({list_id: "list_123"})
      expect(list.id_for_path).to eq("list_123")
    end

    it "returns simple ID as-is" do
      list = described_class.new(id: "simple_id")
      expect(list.id).to eq("simple_id")
      expect(list.id_for_path).to eq("simple_id")
    end

    it "returns nil for unpersisted list" do
      list = described_class.new({})
      expect(list.id_for_path).to be_nil
    end
  end

  describe "#save" do
    let(:list) { described_class.new(list_attributes) }

    it "raises error for unpersisted list" do
      unpersisted = described_class.new({})
      expect { unpersisted.save }.to raise_error(
        Attio::InvalidRequestError,
        "Cannot save a list without an ID"
      )
    end

    it "returns self if nothing changed" do
      expect(list.save).to eq(list)
    end

    it "calls update when changes exist" do
      list.name = "Updated Contacts"

      expect(described_class).to receive(:update).with(
        "list_123",
        {name: "Updated Contacts"}
      )

      list.save
    end

    it "handles simple ID format" do
      simple_list = described_class.new(id: "simple_id", name: "Test")
      simple_list.name = "Updated"

      expect(described_class).to receive(:update).with(
        "simple_id",
        {name: "Updated"}
      )

      simple_list.save
    end
  end

  describe "#destroy" do
    it "raises NotImplementedError" do
      list = described_class.new(list_attributes)
      expect { list.destroy }.to raise_error(
        NotImplementedError,
        "Lists cannot be deleted via the Attio API"
      )
    end
  end

  describe "#entries" do
    let(:list) { described_class.new(list_attributes) }
    let(:client) { instance_double(Attio::Client) }
    let(:response) { {"data" => [{"id" => "entry_1"}, {"id" => "entry_2"}]} }

    before do
      allow(Attio).to receive(:client).and_return(client)
    end

    it "fetches entries using POST query endpoint" do
      allow(client).to receive(:post).with(
        "lists/list_123/entries/query",
        {}
      ).and_return(response)

      entries = list.entries
      expect(entries).to eq([{"id" => "entry_1"}, {"id" => "entry_2"}])
    end

    it "passes query parameters" do
      params = {filter: {name: "Test"}, limit: 10}

      allow(client).to receive(:post).with(
        "lists/list_123/entries/query",
        params
      ).and_return(response)

      result = list.entries(params)
      expect(result).to eq([{"id" => "entry_1"}, {"id" => "entry_2"}])
    end

    it "handles custom API key" do
      allow(Attio).to receive(:client).with(api_key: "custom_key").and_return(client)
      allow(client).to receive(:post).and_return(response)

      result = list.entries({}, api_key: "custom_key")
      expect(result).to eq([{"id" => "entry_1"}, {"id" => "entry_2"}])
    end

    it "returns empty array when no data" do
      allow(client).to receive(:post).and_return({})

      expect(list.entries).to eq([])
    end

    it "handles simple ID format" do
      simple_list = described_class.new(id: "simple_id")

      allow(client).to receive(:post).with(
        "lists/simple_id/entries/query",
        {}
      ).and_return(response)

      result = simple_list.entries
      expect(result).to eq([{"id" => "entry_1"}, {"id" => "entry_2"}])
    end
  end

  describe ".list" do
    it "is available as an API operation" do
      expect(described_class).to respond_to(:list)
    end
  end

  describe ".retrieve" do
    it "is available as an API operation" do
      expect(described_class).to respond_to(:retrieve)
    end
  end

  describe ".create" do
    it "is available as an API operation" do
      expect(described_class).to respond_to(:create)
    end
  end

  describe ".update" do
    it "is available as an API operation" do
      expect(described_class).to respond_to(:update)
    end
  end

  describe "attribute accessors" do
    let(:list) { described_class.new(list_attributes) }

    it "provides read access to attributes" do
      expect(list.name).to eq("Contacts")
      expect(list.workspace_access).to eq("collaborative")
    end

    it "allows updating writable attributes" do
      list.name = "Updated Name"
      expect(list.name).to eq("Updated Name")
      expect(list.changed?).to be true
      expect(list.changed_attributes).to eq({name: "Updated Name"})
    end

    it "provides read-only access to certain attributes" do
      expect(list.api_slug).to eq("contacts")
      expect(list.workspace_id).to eq("ws_123")

      # These should not have setters
      expect(list).not_to respond_to(:api_slug=)
      expect(list).not_to respond_to(:workspace_id=)
    end
  end
end
