# frozen_string_literal: true

require "spec_helper"

RSpec.describe Attio::Entry do
  let(:list_id) { "test-list-id" }
  let(:entry_id) { "test-entry-id" }
  let(:entry_data) do
    {
      id: {
        workspace_id: "test-workspace",
        list_id: list_id,
        entry_id: entry_id
      },
      parent_record_id: "test-record-id",
      parent_object: "people",
      created_at: "2024-01-01T00:00:00Z",
      entry_values: {
        status: "active",
        priority: "high"
      }
    }
  end

  describe ".list" do
    let(:response) do
      {
        "data" => [entry_data],
        "has_more" => false
      }
    end

    before do
      allow(described_class).to receive(:execute_request).and_return(response)
    end

    it "sends a POST request to the correct endpoint" do
      expect(described_class).to receive(:execute_request).with(
        :POST,
        "lists/#{list_id}/entries/query",
        {},
        {}
      )

      described_class.list(list: list_id)
    end

    it "returns a ListObject" do
      result = described_class.list(list: list_id)
      expect(result).to be_a(Attio::APIResource::ListObject)
      expect(result.data.first).to be_a(described_class)
    end

    it "accepts query parameters" do
      query_params = {
        filter: {status: "active"},
        sorts: [{attribute: "created_at", direction: "desc"}],
        limit: 10,
        offset: 0
      }

      expect(described_class).to receive(:execute_request).with(
        :POST,
        "lists/#{list_id}/entries/query",
        query_params,
        {}
      )

      described_class.list(list: list_id, **query_params)
    end

    it "requires a list parameter" do
      expect { described_class.list }.to raise_error(ArgumentError, "List identifier is required")
    end
  end

  describe ".create" do
    let(:create_params) do
      {
        parent_record_id: "test-record-id",
        parent_object: "people",
        entry_values: {
          status: "active",
          priority: "high"
        }
      }
    end

    let(:response) do
      {
        "data" => entry_data
      }
    end

    before do
      allow(described_class).to receive(:execute_request).and_return(response)
    end

    it "sends a POST request with the correct data structure" do
      expect(described_class).to receive(:execute_request).with(
        :POST,
        "lists/#{list_id}/entries",
        {data: create_params},
        {}
      )

      described_class.create(list: list_id, **create_params)
    end

    it "returns an Entry instance" do
      result = described_class.create(list: list_id, **create_params)
      expect(result).to be_a(described_class)
      expect(result.parent_record_id).to eq("test-record-id")
    end

    it "requires a list parameter" do
      expect { described_class.create(**create_params) }.to raise_error(ArgumentError, "List identifier is required")
    end

    it "requires parent_record_id and parent_object" do
      expect { described_class.create(list: list_id) }.to raise_error(ArgumentError, "parent_record_id and parent_object are required")
    end
  end

  describe ".retrieve" do
    let(:response) do
      {
        "data" => entry_data
      }
    end

    before do
      allow(described_class).to receive(:execute_request).and_return(response)
    end

    it "sends a GET request to the correct endpoint" do
      expect(described_class).to receive(:execute_request).with(
        :GET,
        "lists/#{list_id}/entries/#{entry_id}",
        {},
        {}
      )

      described_class.retrieve(list: list_id, entry_id: entry_id)
    end

    it "returns an Entry instance" do
      result = described_class.retrieve(list: list_id, entry_id: entry_id)
      expect(result).to be_a(described_class)
      expect(result.id).to eq(entry_data[:id])
    end

    it "requires both list and entry_id" do
      expect { described_class.retrieve(list: list_id) }.to raise_error(ArgumentError, "Entry ID is required")
      expect { described_class.retrieve(entry_id: entry_id) }.to raise_error(ArgumentError, "List identifier is required")
    end
  end

  describe ".update" do
    let(:update_params) do
      {
        entry_values: {
          status: "completed",
          priority: "low"
        }
      }
    end

    let(:response) do
      {
        "data" => entry_data.merge(entry_values: update_params[:entry_values])
      }
    end

    before do
      allow(described_class).to receive(:execute_request).and_return(response)
    end

    it "sends a PATCH request with the correct data" do
      expect(described_class).to receive(:execute_request).with(
        :PATCH,
        "lists/#{list_id}/entries/#{entry_id}",
        {data: update_params},
        {}
      )

      described_class.update(list: list_id, entry_id: entry_id, **update_params)
    end

    it "supports append mode for multiselect values" do
      expect(described_class).to receive(:execute_request).with(
        :PATCH,
        "lists/#{list_id}/entries/#{entry_id}",
        {data: update_params, mode: "append"},
        {}
      )

      described_class.update(list: list_id, entry_id: entry_id, mode: "append", **update_params)
    end

    it "returns an updated Entry instance" do
      result = described_class.update(list: list_id, entry_id: entry_id, **update_params)
      expect(result).to be_a(described_class)
    end
  end

  describe ".delete" do
    before do
      allow(described_class).to receive(:execute_request).and_return({})
    end

    it "sends a DELETE request to the correct endpoint" do
      expect(described_class).to receive(:execute_request).with(
        :DELETE,
        "lists/#{list_id}/entries/#{entry_id}",
        {},
        {}
      )

      described_class.delete(list: list_id, entry_id: entry_id)
    end

    it "returns true on success" do
      result = described_class.delete(list: list_id, entry_id: entry_id)
      expect(result).to be(true)
    end
  end

  describe ".assert_by_parent" do
    let(:assert_params) do
      {
        parent_record_id: "test-record-id",
        parent_object: "people",
        entry_values: {
          status: "active"
        }
      }
    end

    let(:response) do
      {
        "data" => entry_data
      }
    end

    before do
      allow(described_class).to receive(:execute_request).and_return(response)
    end

    it "sends a PUT request to the correct endpoint" do
      expect(described_class).to receive(:execute_request).with(
        :PUT,
        "lists/#{list_id}/entries",
        {data: assert_params},
        {}
      )

      described_class.assert_by_parent(list: list_id, **assert_params)
    end

    it "returns an Entry instance" do
      result = described_class.assert_by_parent(list: list_id, **assert_params)
      expect(result).to be_a(described_class)
    end
  end

  describe ".list_attribute_values" do
    let(:attribute_id) { "test-attribute-id" }
    let(:response) do
      {
        "data" => [
          {value: "option1", label: "Option 1"},
          {value: "option2", label: "Option 2"}
        ]
      }
    end

    before do
      allow(described_class).to receive(:execute_request).and_return(response)
    end

    it "sends a GET request to the correct endpoint" do
      expect(described_class).to receive(:execute_request).with(
        :GET,
        "lists/#{list_id}/entries/#{entry_id}/attributes/#{attribute_id}/values",
        {},
        {}
      )

      described_class.list_attribute_values(list: list_id, entry_id: entry_id, attribute_id: attribute_id)
    end

    it "returns the values array" do
      result = described_class.list_attribute_values(list: list_id, entry_id: entry_id, attribute_id: attribute_id)
      expect(result).to eq(response["data"])
    end
  end

  describe "instance methods" do
    let(:entry) { described_class.new(entry_data) }

    describe "#parent_record_id" do
      it "returns the parent record ID" do
        expect(entry.parent_record_id).to eq("test-record-id")
      end
    end

    describe "#parent_object" do
      it "returns the parent object type" do
        expect(entry.parent_object).to eq("people")
      end
    end

    describe "#entry_values" do
      it "returns the entry values" do
        expect(entry.entry_values).to eq(entry_data[:entry_values])
      end
    end

    describe "#list_id" do
      it "extracts the list ID from the nested ID" do
        expect(entry.list_id).to eq(list_id)
      end
    end

    describe "#save" do
      let(:updated_values) { {status: "completed"} }

      before do
        entry.entry_values = entry.entry_values.merge(updated_values)
        allow(described_class).to receive(:execute_request).and_return(
          "data" => entry_data.merge(entry_values: entry.entry_values)
        )
      end

      it "updates the entry with changed values" do
        expect(described_class).to receive(:execute_request).with(
          :PATCH,
          "lists/#{list_id}/entries/#{entry_id}",
          {data: {entry_values: entry.entry_values}},
          {}
        )

        entry.save
      end
    end

    describe "#destroy" do
      before do
        allow(described_class).to receive(:execute_request).and_return({})
      end

      it "deletes the entry" do
        expect(described_class).to receive(:execute_request).with(
          :DELETE,
          "lists/#{list_id}/entries/#{entry_id}",
          {},
          {}
        )

        expect(entry.destroy).to be(true)
      end
    end
  end
end
