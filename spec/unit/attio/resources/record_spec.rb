# frozen_string_literal: true

require "spec_helper"
require "webmock/rspec"

RSpec.describe Attio::Record do
  before do
    # Disable VCR for these unit tests to use WebMock instead
    VCR.turn_off!
    WebMock.enable!
  end

  after do
    VCR.turn_on!
  end

  describe ".list" do
    let(:list_response) do
      {
        "data" => [
          {
            "id" => {
              "workspace_id" => "a96c9c20-442b-43cd-a94b-3d4683051661",
              "object_id" => "445e7c02-0068-4b3c-8937-aebbf7530920",
              "record_id" => "0174bfac-74b9-41de-b757-c6fa2a68ab00"
            },
            "created_at" => "2025-07-22T15:07:00.895000000Z",
            "web_url" => "https://app.attio.com/r-and-k-tech-llc/person/0174bfac-74b9-41de-b757-c6fa2a68ab00",
            "values" => {
              "name" => [
                {
                  "first_name" => "Phone",
                  "last_name" => "Test",
                  "full_name" => "Phone Test"
                }
              ]
            }
          }
        ]
      }
    end

    it "lists records for an object" do
      stub_request(:post, "https://api.attio.com/v2/objects/people/records/query")
        .with(body: {"limit" => 2}.to_json)
        .to_return(
          status: 200,
          body: list_response.to_json,
          headers: {"Content-Type" => "application/json"}
        )

      result = described_class.list(object: "people", limit: 2)
      expect(result).to be_a(Attio::APIResource::ListObject)
      expect(result.first).to be_a(described_class) if result.any?
    end

    it "supports filtering" do
      stub_request(:post, "https://api.attio.com/v2/objects/people/records/query")
        .with(body: {"filter" => {"name" => {"$contains" => "Test"}}, "limit" => 1}.to_json)
        .to_return(
          status: 200,
          body: list_response.to_json,
          headers: {"Content-Type" => "application/json"}
        )

      filter = {name: {"$contains" => "Test"}}
      result = described_class.list(object: "people", filter: filter, limit: 1)
      expect(result).to be_a(Attio::APIResource::ListObject)
    end

    it "supports sorting" do
      stub_request(:post, "https://api.attio.com/v2/objects/people/records/query")
        .with(body: {"sort" => {"field" => "created_at", "direction" => "desc"}, "limit" => 2}.to_json)
        .to_return(
          status: 200,
          body: list_response.to_json,
          headers: {"Content-Type" => "application/json"}
        )

      result = described_class.list(object: "people", sort: {field: "created_at", direction: "desc"}, limit: 2)
      expect(result).to be_a(Attio::APIResource::ListObject)
    end
  end

  describe ".create" do
    let(:create_response) do
      {
        "data" => {
          "id" => {
            "workspace_id" => "a96c9c20-442b-43cd-a94b-3d4683051661",
            "object_id" => "445e7c02-0068-4b3c-8937-aebbf7530920",
            "record_id" => "a9ccd85f-921f-49c1-8b0a-80b2ae723056"
          },
          "created_at" => "2025-07-27T01:45:27.220000000Z",
          "web_url" => "https://app.attio.com/r-and-k-tech-llc/person/a9ccd85f-921f-49c1-8b0a-80b2ae723056",
          "values" => {
            "name" => [
              {
                "first_name" => "Test",
                "last_name" => "PersonVCR",
                "full_name" => "Test PersonVCR"
              }
            ]
          }
        }
      }
    end

    it "creates a new record" do
      stub_request(:post, "https://api.attio.com/v2/objects/people/records")
        .with(
          body: {
            "data" => {
              "values" => {
                "name" => {
                  "first_name" => "Test",
                  "last_name" => "PersonVCR",
                  "full_name" => "Test PersonVCR"
                }
              }
            }
          }.to_json
        )
        .to_return(
          status: 200,
          body: create_response.to_json,
          headers: {"Content-Type" => "application/json"}
        )

      result = described_class.create(
        object: "people",
        values: {
          name: {
            first_name: "Test",
            last_name: "PersonVCR",
            full_name: "Test PersonVCR"
          }
        }
      )

      expect(result).to be_a(described_class)
      expect(result.id).not_to be_nil
      expect(result.persisted?).to be true
    end

    it "handles simple scalar values" do
      simple_response = create_response.dup
      simple_response["data"]["values"]["name"][0]["first_name"] = "Simple"
      simple_response["data"]["values"]["name"][0]["last_name"] = "SimpleVCR"
      simple_response["data"]["values"]["name"][0]["full_name"] = "Simple SimpleVCR"

      stub_request(:post, "https://api.attio.com/v2/objects/people/records")
        .with(
          body: {
            "data" => {
              "values" => {
                "name" => {
                  "first_name" => "Simple",
                  "last_name" => "SimpleVCR",
                  "full_name" => "Simple SimpleVCR"
                }
              }
            }
          }.to_json
        )
        .to_return(
          status: 200,
          body: simple_response.to_json,
          headers: {"Content-Type" => "application/json"}
        )

      result = described_class.create(
        object: "people",
        values: {
          name: {
            first_name: "Simple",
            last_name: "SimpleVCR",
            full_name: "Simple SimpleVCR"
          }
        }
      )

      expect(result).to be_a(described_class)
      expect(result.id).not_to be_nil
    end
  end

  describe ".retrieve" do
    it "retrieves a specific record" do
      record_id = "a9ccd85f-921f-49c1-8b0a-80b2ae723056"

      retrieve_response = {
        "data" => {
          "id" => {
            "workspace_id" => "a96c9c20-442b-43cd-a94b-3d4683051661",
            "object_id" => "445e7c02-0068-4b3c-8937-aebbf7530920",
            "record_id" => record_id
          },
          "created_at" => "2025-07-27T01:45:27.220000000Z",
          "values" => {
            "name" => [
              {
                "first_name" => "Retrieve",
                "last_name" => "RetrieveVCR",
                "full_name" => "Retrieve RetrieveVCR"
              }
            ]
          }
        }
      }

      stub_request(:get, "https://api.attio.com/v2/objects/people/records/#{record_id}")
        .to_return(
          status: 200,
          body: retrieve_response.to_json,
          headers: {"Content-Type" => "application/json"}
        )

      retrieved = described_class.retrieve(object: "people", record_id: record_id)
      expect(retrieved).to be_a(described_class)
      expect(retrieved.id["record_id"]).to eq(record_id)
    end
  end

  describe ".update" do
    let(:record_id) { "a9ccd85f-921f-49c1-8b0a-80b2ae723056" }

    let(:updated_person_values) do
      {name: {first_name: "Updated", last_name: "UpdatedVCR", full_name: "Updated UpdatedVCR"}}
    end

    it "updates a record" do
      update_response = {
        "data" => {
          "id" => {
            "workspace_id" => "a96c9c20-442b-43cd-a94b-3d4683051661",
            "object_id" => "445e7c02-0068-4b3c-8937-aebbf7530920",
            "record_id" => record_id
          },
          "created_at" => "2025-07-27T01:45:27.220000000Z",
          "values" => {
            "name" => [
              {
                "first_name" => "Updated",
                "last_name" => "UpdatedVCR",
                "full_name" => "Updated UpdatedVCR"
              }
            ]
          }
        }
      }

      stub_request(:put, "https://api.attio.com/v2/objects/people/records/#{record_id}")
        .with(
          body: {"data" => {"values" => updated_person_values}}.to_json
        )
        .to_return(
          status: 200,
          body: update_response.to_json,
          headers: {"Content-Type" => "application/json"}
        )

      updated = described_class.update(
        object: "people",
        record_id: record_id,
        data: {values: updated_person_values}
      )

      expect(updated).to be_a(described_class)
      expect(updated.id["record_id"]).to eq(record_id)
    end
  end

  describe "instance methods" do
    let(:record) do
      # Create a record instance from mock data
      described_class.new({
        "id" => {
          "workspace_id" => "a96c9c20-442b-43cd-a94b-3d4683051661",
          "object_id" => "445e7c02-0068-4b3c-8937-aebbf7530920",
          "record_id" => "instance-test-record"
        },
        "created_at" => "2025-07-27T01:45:27.220000000Z",
        "object_api_slug" => "people",
        "values" => {
          "name" => [
            {
              "first_name" => "Instance",
              "last_name" => "InstanceVCR",
              "full_name" => "Instance InstanceVCR"
            }
          ]
        }
      })
    end

    describe "#save" do
      it "updates the record when changed" do
        # Mock the record being changed by directly modifying an attribute
        record[:name] = "New Name"

        stub_request(:patch, "https://api.attio.com/v2/objects/people/records/instance-test-record")
          .with(
            body: {
              "data" => {
                "values" => {
                  "name" => {"value" => "New Name"}
                }
              }
            }.to_json
          )
          .to_return(
            status: 200,
            body: {
              "data" => record.to_h.merge("values" => {"name" => [{"value" => "New Name"}]})
            }.to_json,
            headers: {"Content-Type" => "application/json"}
          )

        result = record.save
        expect(result).to eq(record)
      end

      it "does nothing when not changed" do
        expect(record.changed?).to be false
        expect(record.save).to eq(record)
      end

      it "raises error when not persisted" do
        unpersisted_record = described_class.new({})
        expect { unpersisted_record.save }.to raise_error(
          Attio::InvalidRequestError,
          "Cannot update a record without an ID"
        )
      end

      it "raises error without object context" do
        record_without_object = described_class.new({
          "id" => {"record_id" => "test"},
          "values" => {}
        })
        expect { record_without_object.save }.to raise_error(
          Attio::InvalidRequestError,
          "Cannot save without object context"
        )
      end
    end

    describe "#destroy" do
      it "deletes the record" do
        stub_request(:delete, "https://api.attio.com/v2/objects/people/records/instance-test-record")
          .to_return(status: 204)

        result = record.destroy
        expect(result).to be true
        expect(record.id).to be_nil
      end

      it "raises error when not persisted" do
        unpersisted_record = described_class.new({})
        expect { unpersisted_record.destroy }.to raise_error(
          Attio::InvalidRequestError,
          "Cannot destroy a record without an ID"
        )
      end

      it "raises error without object context" do
        record_without_object = described_class.new({
          "id" => {"record_id" => "test"},
          "values" => {}
        })
        expect { record_without_object.destroy }.to raise_error(
          Attio::InvalidRequestError,
          "Cannot destroy without object context"
        )
      end
    end

    describe "#add_to_list" do
      it "adds the record to a list" do
        list_id = "test-list-id"

        # Mock List.retrieve
        list = instance_double(Attio::List)
        allow(Attio::List).to receive(:retrieve).with(list_id).and_return(list)
        allow(list).to receive(:add_record).with(record.id).and_return(true)

        result = record.add_to_list(list_id)
        expect(result).to be true
      end
    end

    describe "#lists" do
      it "retrieves lists containing the record" do
        # Mock List.list instead of direct HTTP call since lists method uses List.list
        allow(Attio::List).to receive(:list).with(record_id: record.id).and_return(
          Attio::APIResource::ListObject.new({"data" => []}, Attio::List, {}, {})
        )

        result = record.lists
        expect(result).to be_a(Attio::APIResource::ListObject)
      end

      it "raises error when not persisted" do
        unpersisted_record = described_class.new({})
        expect { unpersisted_record.lists }.to raise_error(
          Attio::InvalidRequestError,
          "Cannot get lists without an ID"
        )
      end
    end

    describe "#to_h" do
      it "returns a hash representation" do
        hash = record.to_h
        expect(hash).to include(
          :id,
          :object_api_slug,
          :created_at,
          :values
        )
        expect(hash[:object_api_slug]).to eq("people")
        expect(hash[:object_id]).to eq("445e7c02-0068-4b3c-8937-aebbf7530920")
        expect(hash[:values]).to include(:name)
      end
    end

    describe "#inspect" do
      it "returns a readable string representation" do
        inspection = record.inspect
        expect(inspection).to include("#<Attio::Record:")
        expect(inspection).to include("object=\"people\"")
        expect(inspection).to include("name:")
      end
    end

    describe "#resource_path" do
      it "returns the correct path" do
        expect(record.resource_path).to eq("objects/people/records/instance-test-record")
      end

      it "raises error without object context" do
        record_without_object = described_class.new({
          "id" => {"record_id" => "test"},
          "values" => {}
        })
        expect { record_without_object.resource_path }.to raise_error(
          Attio::InvalidRequestError,
          "Cannot generate path without object context"
        )
      end
    end

    describe "attribute accessors" do
      it "provides access to values as attributes" do
        # The name value is extracted as the full hash from the array
        expect(record[:name]).to eq({
          "first_name" => "Instance",
          "last_name" => "InstanceVCR",
          "full_name" => "Instance InstanceVCR"
        })
      end

      it "allows setting attribute values" do
        record[:email] = "test@example.com"
        expect(record[:email]).to eq("test@example.com")
        expect(record.changed?).to be true
      end
    end
  end

  describe ".batch_create" do
    it "creates multiple records" do
      batch_response = {
        "data" => [
          {
            "id" => {"record_id" => "batch-1"},
            "values" => {"name" => [{"value" => "Batch 1"}]}
          },
          {
            "id" => {"record_id" => "batch-2"},
            "values" => {"name" => [{"value" => "Batch 2"}]}
          }
        ]
      }

      stub_request(:post, "https://api.attio.com/v2/records/batch")
        .with(
          body: {
            "data" => [
              {"values" => {"name" => {"value" => "Batch 1"}}},
              {"values" => {"name" => {"value" => "Batch 2"}}}
            ]
          }.to_json
        )
        .to_return(
          status: 200,
          body: batch_response.to_json,
          headers: {"Content-Type" => "application/json"}
        )

      records = [
        {values: {name: "Batch 1"}},
        {values: {name: "Batch 2"}}
      ]

      result = described_class.batch_create(object: "people", records: records)
      expect(result).to be_an(Array)
      expect(result.size).to eq(2)
      expect(result.first).to be_a(described_class)
    end

    it "raises error without object" do
      expect { described_class.batch_create(records: []) }.to raise_error(ArgumentError)
    end

    it "raises error with invalid records" do
      expect { described_class.batch_create(object: "people", records: "not-array") }.to raise_error(
        ArgumentError,
        "Records must be an array"
      )
    end

    it "raises error with empty records" do
      expect { described_class.batch_create(object: "people", records: []) }.to raise_error(
        ArgumentError,
        "Records cannot be empty"
      )
    end
  end

  describe ".batch_update" do
    it "updates multiple records" do
      batch_response = {
        "data" => [
          {
            "id" => {"record_id" => "update-1"},
            "values" => {"name" => [{"value" => "Updated 1"}]}
          },
          {
            "id" => {"record_id" => "update-2"},
            "values" => {"name" => [{"value" => "Updated 2"}]}
          }
        ]
      }

      stub_request(:put, "https://api.attio.com/v2/records/batch")
        .with(
          body: {
            "data" => [
              {
                "id" => {"record_id" => "update-1"},
                "values" => {"name" => {"value" => "Updated 1"}}
              },
              {
                "id" => {"record_id" => "update-2"},
                "values" => {"name" => {"value" => "Updated 2"}}
              }
            ]
          }.to_json
        )
        .to_return(
          status: 200,
          body: batch_response.to_json,
          headers: {"Content-Type" => "application/json"}
        )

      records = [
        {record_id: "update-1", values: {name: "Updated 1"}},
        {record_id: "update-2", values: {name: "Updated 2"}}
      ]

      result = described_class.batch_update(object: "people", records: records)
      expect(result).to be_an(Array)
      expect(result.size).to eq(2)
    end
  end

  describe ".create_batch" do
    it "creates multiple records (legacy method)" do
      batch_response = {
        "data" => [
          {
            "id" => {"record_id" => "legacy-1"},
            "values" => {"name" => [{"value" => "Legacy 1"}]}
          }
        ]
      }

      stub_request(:post, "https://api.attio.com/v2/objects/batch")
        .with(
          body: {
            "object" => "people",
            "data" => [
              {"values" => {"name" => {"value" => "Legacy 1"}}}
            ]
          }.to_json
        )
        .to_return(
          status: 200,
          body: batch_response.to_json,
          headers: {"Content-Type" => "application/json"}
        )

      records = [{values: {name: "Legacy 1"}}]

      result = described_class.create_batch(object: "people", records: records)
      expect(result).to be_an(Array)
      expect(result.first).to be_a(described_class)
    end
  end

  describe ".search" do
    it "searches records" do
      search_response = {
        "data" => [
          {
            "id" => {"record_id" => "search-result"},
            "values" => {"name" => [{"value" => "Search Result"}]}
          }
        ]
      }

      stub_request(:post, "https://api.attio.com/v2/objects/people/records/query")
        .with(body: {"q" => "test query"}.to_json)
        .to_return(
          status: 200,
          body: search_response.to_json,
          headers: {"Content-Type" => "application/json"}
        )

      result = described_class.search("test query", object: "people")
      expect(result).to be_a(Attio::APIResource::ListObject)
    end
  end

  describe ".all" do
    it "is an alias for list" do
      stub_request(:post, "https://api.attio.com/v2/objects/people/records/query")
        .with(body: {}.to_json)
        .to_return(
          status: 200,
          body: {"data" => []}.to_json,
          headers: {"Content-Type" => "application/json"}
        )

      result = described_class.all(object: "people")
      expect(result).to be_a(Attio::APIResource::ListObject)
    end
  end

  describe ".get" do
    it "is an alias for retrieve" do
      record_id = "alias-test"

      stub_request(:get, "https://api.attio.com/v2/objects/people/records/#{record_id}")
        .to_return(
          status: 200,
          body: {"data" => {"id" => {"record_id" => record_id}}}.to_json,
          headers: {"Content-Type" => "application/json"}
        )

      result = described_class.get(object: "people", record_id: record_id)
      expect(result).to be_a(described_class)
    end
  end

  describe ".find" do
    it "is an alias for retrieve" do
      record_id = "find-test"

      stub_request(:get, "https://api.attio.com/v2/objects/people/records/#{record_id}")
        .to_return(
          status: 200,
          body: {"data" => {"id" => {"record_id" => record_id}}}.to_json,
          headers: {"Content-Type" => "application/json"}
        )

      result = described_class.find(object: "people", record_id: record_id)
      expect(result).to be_a(described_class)
    end
  end

  describe "parameter validation" do
    describe ".create" do
      it "raises error without object" do
        expect { described_class.create(values: {}) }.to raise_error(ArgumentError)
      end

      it "raises error without values" do
        expect { described_class.create(object: "people") }.to raise_error(
          ArgumentError,
          "Must provide object and either values or data.values"
        )
      end

      it "raises error with non-hash values" do
        expect { described_class.create(object: "people", values: "not-hash") }.to raise_error(
          ArgumentError,
          "Values must be a Hash"
        )
      end

      it "handles data parameter style" do
        stub_request(:post, "https://api.attio.com/v2/objects/people/records")
          .with(
            body: {"data" => {"values" => {"name" => {"value" => "Data Style"}}}}.to_json
          )
          .to_return(
            status: 200,
            body: {"data" => {"id" => {"record_id" => "data-style"}}}.to_json,
            headers: {"Content-Type" => "application/json"}
          )

        result = described_class.create(
          object: "people",
          data: {values: {name: "Data Style"}}
        )
        expect(result).to be_a(described_class)
      end
    end

    describe ".retrieve" do
      it "raises error without object" do
        expect { described_class.retrieve(record_id: "123") }.to raise_error(ArgumentError)
      end

      it "raises error without record_id" do
        expect { described_class.retrieve(object: "people") }.to raise_error(ArgumentError)
      end

      it "handles nested id hash" do
        nested_id = {"record_id" => "nested-123"}

        stub_request(:get, "https://api.attio.com/v2/objects/people/records/nested-123")
          .to_return(
            status: 200,
            body: {"data" => {"id" => nested_id}}.to_json,
            headers: {"Content-Type" => "application/json"}
          )

        result = described_class.retrieve(object: "people", record_id: nested_id)
        expect(result).to be_a(described_class)
      end
    end

    describe ".update" do
      it "raises error without object" do
        expect { described_class.update(record_id: "123", data: {}) }.to raise_error(ArgumentError)
      end

      it "raises error without record_id" do
        expect { described_class.update(object: "people", data: {}) }.to raise_error(ArgumentError)
      end
    end
  end

  describe "value processing" do
    it "extracts simple values from API format" do
      record = described_class.new({
        "values" => {
          "email" => [{"value" => "test@example.com"}],
          "phone" => [{"value" => "+1234567890"}]
        }
      })

      expect(record[:email]).to eq("test@example.com")
      expect(record[:phone]).to eq("+1234567890")
    end

    it "handles array values" do
      record = described_class.new({
        "values" => {
          "tags" => [
            {"value" => "tag1"},
            {"value" => "tag2"}
          ]
        }
      })

      expect(record[:tags]).to eq(["tag1", "tag2"])
    end

    it "handles reference values" do
      record = described_class.new({
        "values" => {
          "company" => [{
            "target_object" => "companies",
            "target_record_id" => "company-123"
          }]
        }
      })

      expect(record[:company]).to eq("companies")
    end

    it "handles complex value objects" do
      record = described_class.new({
        "values" => {
          "address" => [{
            "line_1" => "123 Main St",
            "city" => "New York",
            "state" => "NY"
          }]
        }
      })

      expect(record[:address]).to include(
        "line_1" => "123 Main St",
        "city" => "New York",
        "state" => "NY"
      )
    end
  end

  describe "filtering" do
    it "handles hash filters" do
      stub_request(:post, "https://api.attio.com/v2/objects/people/records/query")
        .with(body: {"filter" => {"status" => "active"}}.to_json)
        .to_return(
          status: 200,
          body: {"data" => []}.to_json,
          headers: {"Content-Type" => "application/json"}
        )

      result = described_class.list(object: "people", filter: {status: "active"})
      expect(result).to be_a(Attio::APIResource::ListObject)
    end

    it "handles array filters as $and" do
      stub_request(:post, "https://api.attio.com/v2/objects/people/records/query")
        .with(body: {"filter" => {"$and" => [{"status" => "active"}, {"type" => "customer"}]}}.to_json)
        .to_return(
          status: 200,
          body: {"data" => []}.to_json,
          headers: {"Content-Type" => "application/json"}
        )

      result = described_class.list(
        object: "people",
        filter: [{status: "active"}, {type: "customer"}]
      )
      expect(result).to be_a(Attio::APIResource::ListObject)
    end
  end

  describe "sorting" do
    it "parses string sort format" do
      stub_request(:post, "https://api.attio.com/v2/objects/people/records/query")
        .with(body: {"sort" => {"field" => "created_at", "direction" => "desc"}}.to_json)
        .to_return(
          status: 200,
          body: {"data" => []}.to_json,
          headers: {"Content-Type" => "application/json"}
        )

      result = described_class.list(object: "people", sort: "created_at:desc")
      expect(result).to be_a(Attio::APIResource::ListObject)
    end

    it "defaults to asc direction" do
      stub_request(:post, "https://api.attio.com/v2/objects/people/records/query")
        .with(body: {"sort" => {"field" => "name", "direction" => "asc"}}.to_json)
        .to_return(
          status: 200,
          body: {"data" => []}.to_json,
          headers: {"Content-Type" => "application/json"}
        )

      result = described_class.list(object: "people", sort: "name")
      expect(result).to be_a(Attio::APIResource::ListObject)
    end
  end
end
