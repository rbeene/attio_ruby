# frozen_string_literal: true

require "spec_helper"
require "webmock/rspec"

RSpec.describe Attio::List do
  # WebMock is already enabled globally

  let(:list_data) do
    {
      "id" => {
        "workspace_id" => "a96c9c20-442b-43cd-a94b-3d4683051661",
        "list_id" => "b557d074-c549-4807-bc01-c4fd74cb419c"
      },
      "api_slug" => "customer_success",
      "created_at" => "2025-07-18T13:50:25.142000000Z",
      "name" => "Customer Success",
      "object_id" => "123e4567-e89b-12d3-a456-426614174000",
      "object_api_slug" => "companies",
      "workspace_access" => "full-access",
      "workspace_member_access" => [
        {
          "level" => "full-access",
          "workspace_member_id" => "1757c0bb-f8e6-4013-b41d-2e49a3ef2c6f"
        }
      ],
      "parent_object" => ["companies"],
      "created_by_actor" => {
        "type" => "workspace-member",
        "id" => "1757c0bb-f8e6-4013-b41d-2e49a3ef2c6f"
      },
      "workspace_id" => "a96c9c20-442b-43cd-a94b-3d4683051661"
    }
  end

  describe ".list" do
    it "lists lists" do
      stub_request(:get, "https://api.attio.com/v2/lists")
        .to_return(
          status: 200,
          body: {"data" => [list_data]}.to_json,
          headers: {"Content-Type" => "application/json"}
        )

      result = described_class.list
      expect(result).to be_a(Attio::APIResource::ListObject)
      expect(result.first).to be_a(described_class)
      expect(result.first.name).to eq("Customer Success")
    end
  end

  describe ".retrieve" do
    it "retrieves a specific list" do
      list_id = "b557d074-c549-4807-bc01-c4fd74cb419c"

      stub_request(:get, "https://api.attio.com/v2/lists/#{list_id}")
        .to_return(
          status: 200,
          body: {"data" => list_data}.to_json,
          headers: {"Content-Type" => "application/json"}
        )

      list = described_class.retrieve(list_id)
      expect(list).to be_a(described_class)
      expect(list.id["list_id"]).to eq(list_id)
      expect(list.name).to eq("Customer Success")
    end
  end

  describe ".create" do
    it "creates a new list with valid parameters" do
      create_response = list_data.merge(
        "api_slug" => "test_list",
        "name" => "Test List"
      )

      stub_request(:post, "https://api.attio.com/v2/lists")
        .with(
          body: {
            "data" => {
              "name" => "Test List",
              "parent_object" => "people",
              "api_slug" => "test_list",
              "workspace_access" => "full-access",
              "workspace_member_access" => []
            }
          }.to_json
        )
        .to_return(
          status: 200,
          body: {"data" => create_response}.to_json,
          headers: {"Content-Type" => "application/json"}
        )

      list = described_class.create({
        object: "people",
        name: "Test List"
      })

      expect(list).to be_a(described_class)
      expect(list.name).to eq("Test List")
      expect(list.api_slug).to eq("test_list")
    end

    it "generates api_slug from name if not provided" do
      create_response = list_data.merge(
        "api_slug" => "complex_list_name",
        "name" => "Complex List Name!"
      )

      stub_request(:post, "https://api.attio.com/v2/lists")
        .with(
          body: {
            "data" => {
              "name" => "Complex List Name!",
              "parent_object" => "people",
              "api_slug" => "complex_list_name_",
              "workspace_access" => "full-access",
              "workspace_member_access" => []
            }
          }.to_json
        )
        .to_return(
          status: 200,
          body: {"data" => create_response}.to_json,
          headers: {"Content-Type" => "application/json"}
        )

      list = described_class.create({
        object: "people",
        name: "Complex List Name!"
      })

      expect(list).to be_a(described_class)
    end

    it "accepts custom api_slug" do
      stub_request(:post, "https://api.attio.com/v2/lists")
        .with(
          body: {
            "data" => {
              "name" => "Test List",
              "parent_object" => "people",
              "api_slug" => "custom_slug",
              "workspace_access" => "full-access",
              "workspace_member_access" => []
            }
          }.to_json
        )
        .to_return(
          status: 200,
          body: {"data" => list_data}.to_json,
          headers: {"Content-Type" => "application/json"}
        )

      list = described_class.create({
        object: "people",
        name: "Test List",
        api_slug: "custom_slug"
      })
      expect(list).to be_a(described_class)
    end

    it "accepts custom workspace_access" do
      stub_request(:post, "https://api.attio.com/v2/lists")
        .with(
          body: {
            "data" => {
              "name" => "Test List",
              "parent_object" => "people",
              "api_slug" => "test_list",
              "workspace_access" => "read-only",
              "workspace_member_access" => []
            }
          }.to_json
        )
        .to_return(
          status: 200,
          body: {"data" => list_data}.to_json,
          headers: {"Content-Type" => "application/json"}
        )

      list = described_class.create({
        object: "people",
        name: "Test List",
        workspace_access: "read-only"
      })
      expect(list).to be_a(described_class)
    end

    it "accepts workspace_member_access" do
      member_access = [{level: "read-only", workspace_member_id: "123"}]

      stub_request(:post, "https://api.attio.com/v2/lists")
        .with(
          body: {
            "data" => {
              "name" => "Test List",
              "parent_object" => "people",
              "api_slug" => "test_list",
              "workspace_access" => "full-access",
              "workspace_member_access" => member_access
            }
          }.to_json
        )
        .to_return(
          status: 200,
          body: {"data" => list_data}.to_json,
          headers: {"Content-Type" => "application/json"}
        )

      list = described_class.create({
        object: "people",
        name: "Test List",
        workspace_member_access: member_access
      })
      expect(list).to be_a(described_class)
    end

    it "validates object is required" do
      expect {
        described_class.create({name: "Test List"})
      }.to raise_error(ArgumentError, "Object identifier is required")
    end
  end

  describe ".update" do
    it "updates a list" do
      list_id = "b557d074-c549-4807-bc01-c4fd74cb419c"
      updated_data = list_data.merge("name" => "Updated List")

      stub_request(:patch, "https://api.attio.com/v2/lists/#{list_id}")
        .with(
          body: {"data" => {"name" => "Updated List"}}.to_json
        )
        .to_return(
          status: 200,
          body: {"data" => updated_data}.to_json,
          headers: {"Content-Type" => "application/json"}
        )

      list = described_class.update(list_id: list_id, name: "Updated List")
      expect(list.name).to eq("Updated List")
    end
  end

  describe ".find_by_slug" do
    it "finds a list by API slug" do
      stub_request(:get, "https://api.attio.com/v2/lists")
        .to_return(
          status: 200,
          body: {"data" => [list_data]}.to_json,
          headers: {"Content-Type" => "application/json"}
        )

      list = described_class.find_by_slug(slug: "customer_success")
      expect(list).to be_a(described_class)
      expect(list.api_slug).to eq("customer_success")
    end

    it "raises NotFoundError when list not found" do
      stub_request(:get, "https://api.attio.com/v2/lists")
        .to_return(
          status: 200,
          body: {"data" => []}.to_json,
          headers: {"Content-Type" => "application/json"}
        )

      expect {
        described_class.find_by_slug(slug: "nonexistent")
      }.to raise_error(Attio::NotFoundError, "List with slug 'nonexistent' not found")
    end
  end

  describe ".for_object" do
    it "returns lists for a specific object" do
      stub_request(:get, "https://api.attio.com/v2/lists?object=companies")
        .to_return(
          status: 200,
          body: {"data" => [list_data]}.to_json,
          headers: {"Content-Type" => "application/json"}
        )

      lists = described_class.for_object(object: "companies")
      expect(lists).to be_a(Attio::APIResource::ListObject)
    end

    it "merges additional parameters" do
      stub_request(:get, "https://api.attio.com/v2/lists")
        .with(query: {"limit" => "10", "object" => "companies"})
        .to_return(
          status: 200,
          body: {"data" => []}.to_json,
          headers: {"Content-Type" => "application/json"}
        )

      result = described_class.for_object(object: "companies", limit: 10)
      expect(result).to be_a(Attio::APIResource::ListObject)
    end
  end

  describe "instance methods" do
    let(:list) { described_class.new(list_data) }

    describe "#initialize" do
      it "sets the name" do
        expect(list.name).to eq("Customer Success")
      end

      it "sets the api_slug" do
        expect(list.api_slug).to eq("customer_success")
      end

      it "sets the object identifiers" do
        expect(list.attio_object_id).to eq("123e4567-e89b-12d3-a456-426614174000")
        expect(list.object_api_slug).to eq("companies")
      end

      it "sets the workspace access" do
        expect(list.workspace_access).to eq("full-access")
      end

      it "sets the created_by_actor" do
        expect(list.created_by_actor).to eq({
          "type" => "workspace-member",
          "id" => "1757c0bb-f8e6-4013-b41d-2e49a3ef2c6f"
        })
      end

      it "sets the workspace_id" do
        expect(list.workspace_id).to eq("a96c9c20-442b-43cd-a94b-3d4683051661")
      end

      context "with minimal data" do
        let(:minimal_data) do
          {
            "id" => list_data["id"],
            "name" => "Test List"
          }
        end
        let(:minimal_list) { described_class.new(minimal_data) }

        it "handles missing api_slug" do
          expect(minimal_list.api_slug).to be_nil
        end

        it "handles missing object identifiers" do
          expect(minimal_list.attio_object_id).to be_nil
          expect(minimal_list.object_api_slug).to be_nil
        end

        it "handles missing workspace_access" do
          expect(minimal_list.workspace_access).to be_nil
        end

        it "handles missing created_by_actor" do
          expect(minimal_list.created_by_actor).to be_nil
        end

        it "handles missing workspace_id" do
          expect(minimal_list.workspace_id).to be_nil
        end
      end
    end

    describe "#resource_path" do
      it "returns the correct path" do
        expect(list.resource_path).to eq("lists/b557d074-c549-4807-bc01-c4fd74cb419c")
      end

      it "handles simple ID format" do
        list = described_class.new({"id" => "simple-id"})
        expect(list.resource_path).to eq("lists/simple-id")
      end

      it "raises error when not persisted" do
        unpersisted_list = described_class.new({})
        expect { unpersisted_list.resource_path }.to raise_error(
          Attio::InvalidRequestError,
          "Cannot generate path without an ID"
        )
      end
    end

    describe "#save" do
      it "saves changes to the list" do
        list[:name] = "Updated Name"

        stub_request(:patch, "https://api.attio.com/v2/lists/b557d074-c549-4807-bc01-c4fd74cb419c")
          .with(
            body: {"data" => {"name" => "Updated Name"}}.to_json
          )
          .to_return(
            status: 200,
            body: {"data" => list_data.merge("name" => "Updated Name")}.to_json,
            headers: {"Content-Type" => "application/json"}
          )

        result = list.save
        expect(result).to eq(list)
      end

      it "does nothing when not changed" do
        expect(list.changed?).to be false
        expect(list.save).to eq(list)
      end

      it "raises error when not persisted without required attributes" do
        unpersisted_list = described_class.new({})
        expect { unpersisted_list.save }.to raise_error(
          Attio::InvalidRequestError,
          "Cannot save a new list without 'object' and 'name' attributes"
        )
      end
    end

    describe "#destroy" do
      it "raises NotImplementedError" do
        expect { list.destroy }.to raise_error(
          NotImplementedError,
          "Lists cannot be deleted via the Attio API"
        )
      end
    end

    describe "#entries" do
      it "gets list entries" do
        entries_data = [
          {
            "id" => "entry-1",
            "record_id" => "record-1",
            "created_at" => "2025-07-27T12:00:00Z"
          }
        ]

        stub_request(:get, "https://api.attio.com/v2/lists/b557d074-c549-4807-bc01-c4fd74cb419c/entries")
          .to_return(
            status: 200,
            body: {"data" => entries_data}.to_json,
            headers: {"Content-Type" => "application/json"}
          )

        entries = list.entries
        expect(entries).to be_an(Array)
        expect(entries.first["id"]).to eq("entry-1")
      end

      it "passes parameters" do
        stub_request(:get, "https://api.attio.com/v2/lists/b557d074-c549-4807-bc01-c4fd74cb419c/entries?limit=10")
          .to_return(
            status: 200,
            body: {"data" => []}.to_json,
            headers: {"Content-Type" => "application/json"}
          )

        entries = list.entries(limit: 10)
        expect(entries).to eq([])
      end

      it "handles empty response" do
        stub_request(:get, "https://api.attio.com/v2/lists/b557d074-c549-4807-bc01-c4fd74cb419c/entries")
          .to_return(
            status: 200,
            body: {}.to_json,
            headers: {"Content-Type" => "application/json"}
          )

        entries = list.entries
        expect(entries).to eq([])
      end
    end

    describe "#add_record" do
      it "adds a record to the list" do
        record_id = "record-123"

        stub_request(:post, "https://api.attio.com/v2/lists/b557d074-c549-4807-bc01-c4fd74cb419c/entries")
          .with(
            body: {"record_id" => record_id}.to_json
          )
          .to_return(
            status: 200,
            body: {"data" => {"id" => "entry-123"}}.to_json,
            headers: {"Content-Type" => "application/json"}
          )

        result = list.add_record(record_id: record_id)
        expect(result).to include("data")
      end
    end

    describe "#remove_record" do
      it "removes a record from the list" do
        entry_id = "entry-123"

        stub_request(:delete, "https://api.attio.com/v2/lists/b557d074-c549-4807-bc01-c4fd74cb419c/entries/#{entry_id}")
          .to_return(status: 204)

        result = list.remove_record(entry_id: entry_id)
        expect(result).to be_nil
      end
    end

    describe "#contains_record?" do
      it "returns true when record is in list" do
        record_id = "record-123"

        stub_request(:get, "https://api.attio.com/v2/lists/b557d074-c549-4807-bc01-c4fd74cb419c/entries?record_id=#{record_id}")
          .to_return(
            status: 200,
            body: {"data" => [{"id" => "entry-1", "record_id" => record_id}]}.to_json,
            headers: {"Content-Type" => "application/json"}
          )

        expect(list.contains_record?(record_id: record_id)).to be true
      end

      it "returns false when record is not in list" do
        record_id = "record-456"

        stub_request(:get, "https://api.attio.com/v2/lists/b557d074-c549-4807-bc01-c4fd74cb419c/entries?record_id=#{record_id}")
          .to_return(
            status: 200,
            body: {"data" => []}.to_json,
            headers: {"Content-Type" => "application/json"}
          )

        expect(list.contains_record?(record_id: record_id)).to be false
      end
    end

    describe "#entry_count" do
      it "returns the number of entries" do
        entries_data = [
          {"id" => "entry-1"},
          {"id" => "entry-2"},
          {"id" => "entry-3"}
        ]

        stub_request(:get, "https://api.attio.com/v2/lists/b557d074-c549-4807-bc01-c4fd74cb419c/entries")
          .to_return(
            status: 200,
            body: {"data" => entries_data}.to_json,
            headers: {"Content-Type" => "application/json"}
          )

        expect(list.entry_count).to eq(3)
      end

      it "returns 0 when no entries" do
        stub_request(:get, "https://api.attio.com/v2/lists/b557d074-c549-4807-bc01-c4fd74cb419c/entries")
          .to_return(
            status: 200,
            body: {"data" => []}.to_json,
            headers: {"Content-Type" => "application/json"}
          )

        expect(list.entry_count).to eq(0)
      end
    end

    describe "#to_h" do
      it "returns a hash representation" do
        hash = list.to_h
        expect(hash).to include(
          :id,
          :name,
          :api_slug,
          :object_id,
          :object_api_slug,
          :workspace_access,
          :created_by_actor,
          :workspace_id
        )
      end

      context "with minimal data" do
        let(:minimal_data) do
          {
            "id" => list_data["id"],
            "name" => "Test List"
          }
        end
        let(:minimal_list) { described_class.new(minimal_data) }
        let(:hash) { minimal_list.to_h }

        it "excludes nil api_slug" do
          expect(hash).not_to have_key(:api_slug)
        end

        it "excludes nil object_id" do
          expect(hash).not_to have_key(:object_id)
        end

        it "excludes nil object_api_slug" do
          expect(hash).not_to have_key(:object_api_slug)
        end

        it "excludes nil workspace_access" do
          expect(hash).not_to have_key(:workspace_access)
        end

        it "excludes nil created_by_actor" do
          expect(hash).not_to have_key(:created_by_actor)
        end

        it "excludes nil workspace_id" do
          expect(hash).not_to have_key(:workspace_id)
        end
      end
    end
  end
end
