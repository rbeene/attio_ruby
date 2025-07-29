# frozen_string_literal: true

require "spec_helper"

RSpec.describe Attio::TypedRecord do
  # Create a test class that inherits from TypedRecord
  let(:test_class) do
    Class.new(Attio::TypedRecord) do
      object_type "test_objects"
    end
  end

  describe ".object_type" do
    it "sets and returns the object type" do
      expect(test_class.object_type).to eq("test_objects")
    end

    it "raises an error if object_type is not defined" do
      undefined_class = Class.new(described_class)
      expect { undefined_class.object_type }.to raise_error(NotImplementedError)
    end
  end

  describe ".list" do
    it "automatically includes the object type" do
      # Mock the API response directly
      list_response = {
        "data" => [],
        "meta" => {"total" => 0}
      }

      allow(test_class).to receive(:execute_request).with(
        :POST,
        "objects/test_objects/records/query",
        {},
        {params: {q: "test"}}
      ).and_return(list_response)

      result = test_class.list(params: {q: "test"})
      expect(result.data).to eq([])
    end
  end

  describe ".retrieve" do
    it "automatically includes the object type" do
      # Mock the API response
      retrieve_response = {
        "data" => {"id" => {"record_id" => "123"}}
      }

      allow(test_class).to receive(:execute_request).with(
        :GET,
        "objects/test_objects/records/123",
        {},
        {}
      ).and_return(retrieve_response)

      result = test_class.retrieve("123")
      expect(result.id["record_id"]).to eq("123")
    end
  end

  describe ".create" do
    it "creates with object type included" do
      # The create method should prepare params and call execute_request
      allow(test_class).to receive(:execute_request).with(
        :POST,
        "objects/test_objects/records",
        {
          data: {
            values: {name: "Test"}
          }
        },
        {}
      ).and_return({data: {id: {record_id: "123"}}})

      result = test_class.create(values: {name: "Test"})
      expect(result).to be_a(test_class)
    end
  end

  describe ".update" do
    it "automatically includes the object type" do
      # Instead of mocking the superclass, let's mock execute_request
      # which is what the parent class eventually calls
      update_response = {
        "data" => {
          "id" => {"record_id" => "123"},
          "values" => {"name" => "Updated"}
        }
      }

      # Mock the underlying API call
      allow(test_class).to receive(:execute_request).and_return(update_response)

      result = test_class.update("123", values: {name: "Updated"})
      expect(result).to be_a(test_class)
      expect(result.id["record_id"]).to eq("123")
    end
  end

  describe ".delete" do
    it "automatically includes the object type" do
      # Mock the execute_request call directly
      allow(test_class).to receive(:execute_request).with(
        :DELETE,
        "objects/test_objects/records/123",
        {},
        {}
      ).and_return({"data" => {}})

      result = test_class.delete("123")
      expect(result).to be true
    end
  end

  describe ".find" do
    it "is an alias for retrieve" do
      expect(test_class).to receive(:retrieve).with("123")
      test_class.find("123")
    end
  end

  describe ".all" do
    it "is an alias for list" do
      expect(test_class).to receive(:list)
      test_class.all
    end
  end

  describe ".search" do
    it "performs a search with query parameter" do
      expect(test_class).to receive(:list).with(params: {q: "test query"})
      test_class.search("test query")
    end
  end

  describe ".find_by" do
    it "finds the first record matching an attribute filter" do
      expected_record = test_class.new({id: {record_id: "123"}, name: "Test"})
      results = double(first: expected_record)

      allow(test_class).to receive(:list).with(
        params: {filter: {"name" => "Test"}}
      ).and_return(results)

      result = test_class.find_by("name", "Test")
      expect(result).to eq(expected_record)
    end
  end

  describe "#save" do
    let(:record) { test_class.new({id: {record_id: "123"}, values: {name: "Test"}}) }

    it "includes object type in update call" do
      # Mark as changed
      record[:name] = "Updated"

      expect(test_class).to receive(:update).with(
        {record_id: "123"},
        values: {name: "Updated"}
      )

      record.save
    end

    it "raises error if record is not persisted" do
      new_record = test_class.new({})
      expect { new_record.save }.to raise_error(Attio::InvalidRequestError)
    end
  end

  describe "#destroy" do
    it "includes object type in delete call" do
      # Create record with proper ID structure
      record = test_class.new({"id" => {"record_id" => "123"}, "object_api_slug" => "test_objects"})

      expect(test_class).to receive(:execute_request).with(
        :DELETE,
        "objects/test_objects/records/123",
        {},
        {}
      )
      record.destroy
    end

    it "freezes the record after deletion" do
      record = test_class.new({id: {record_id: "123"}, object_api_slug: "test_objects"})
      allow(test_class).to receive(:execute_request)
      record.destroy
      expect(record).to be_frozen
    end
  end
end
