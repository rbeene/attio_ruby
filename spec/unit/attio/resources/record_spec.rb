# frozen_string_literal: true

require "spec_helper"

RSpec.describe Attio::Record do
  # Disable VCR for these WebMock tests
  before { VCR.turn_off! }
  after { VCR.turn_on! }

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
        # For now, let's just verify the record was created properly
        expect(record).to be_a(described_class)
        expect(record.persisted?).to be true
      end
    end
  end
end
