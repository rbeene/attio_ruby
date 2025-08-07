# frozen_string_literal: true

require "spec_helper"

RSpec.describe Attio::Deal do
  let(:deal_data) do
    {
      "id" => {"object_id" => "obj_deals", "record_id" => "rec_deal123"},
      "object_api_slug" => "deals",
      "created_at" => Time.now.iso8601,
      "values" => {
        "name" => [{"value" => "Enterprise Deal"}],
        "value" => [{
          "active_from" => Time.now.iso8601,
          "active_until" => nil,
          "created_by_actor" => {"type" => "api-token", "id" => "token_123"},
          "currency_code" => "USD",
          "currency_value" => 150000,
          "attribute_type" => "currency"
        }],
        "stage" => [{
          "active_from" => Time.now.iso8601,
          "active_until" => nil,
          "created_by_actor" => {"type" => "api-token", "id" => "token_123"},
          "status" => {
            "id" => {
              "workspace_id" => "ws_123",
              "object_id" => "obj_deals",
              "attribute_id" => "attr_stage",
              "status_id" => "status_456"
            },
            "title" => "negotiating",
            "is_archived" => false,
            "target_time_in_status" => "P0Y0M0DT0H0M0S",
            "celebration_enabled" => false
          },
          "attribute_type" => "status"
        }],
        "close_date" => [{"value" => "2024-12-31"}],
        "probability" => [{"value" => 75}],
        "owner" => [{
          "active_from" => Time.now.iso8601,
          "active_until" => nil,
          "created_by_actor" => {"type" => "api-token", "id" => "token_123"},
          "referenced_actor_type" => "workspace-member",
          "referenced_actor_id" => "member_123",
          "attribute_type" => "actor-reference"
        }],
        "company" => [{
          "active_from" => Time.now.iso8601,
          "active_until" => nil,
          "created_by_actor" => {"type" => "api-token", "id" => "token_123"},
          "target_object" => "companies", 
          "target_record_id" => "rec_company456",
          "attribute_type" => "record-reference"
        }]
      }
    }
  end

  describe "class configuration" do
    it "has the correct object type" do
      expect(described_class.object_type).to eq("deals")
    end

    it "inherits from TypedRecord" do
      expect(described_class).to be < Attio::TypedRecord
    end
  end

  describe ".create" do
    before do
      stub_request(:post, "https://api.attio.com/v2/objects/deals/records")
        .with(
          body: {
            data: {
              values: {
                name: "New Deal",
                value: 100000,
                stage: "open",
                owner: "test@example.com"
              }
            }
          }.to_json,
          headers: {
            "Authorization" => "Bearer test_api_key",
            "Content-Type" => "application/json"
          }
        )
        .to_return(status: 201, body: {"data" => deal_data}.to_json, headers: {"Content-Type" => "application/json"})
    end

    it "creates a deal with simplified interface" do
      deal = described_class.create(
        name: "New Deal",
        value: 100000,
        status: "open",
        owner: "test@example.com"
      )

      expect(deal).to be_a(described_class)
      expect(deal[:name]).to eq("Enterprise Deal")
      expect(deal[:value]).to be_a(Hash)
      expect(deal[:value]["currency_value"]).to eq(150000)
      expect(deal[:stage]).to be_a(Hash)
      expect(deal[:stage]["status"]["title"]).to eq("negotiating")
    end
  end

  describe "instance methods" do
    let(:deal) { described_class.new(deal_data) }

    describe "#name" do
      it "returns the deal name" do
        expect(deal.name).to eq("Enterprise Deal")
      end
    end

    describe "#value" do
      it "returns the deal value" do
        expect(deal.value).to be_a(Hash)
        expect(deal.value["currency_value"]).to eq(150000)
      end
    end

    describe "#stage" do
      it "returns the deal stage" do
        expect(deal.stage).to be_a(Hash)
        expect(deal.stage["status"]["title"]).to eq("negotiating")
      end
    end
    
    describe "#status" do
      it "returns the deal stage (alias for compatibility)" do
        expect(deal.status).to be_a(Hash)
        expect(deal.status["status"]["title"]).to eq("negotiating")
      end
    end

    # Close date and probability methods are commented out
    # since these attributes may not exist by default

    describe "#company" do
      it "returns the associated company reference" do
        expect(deal.company).to be_a(Hash)
        expect(deal.company["target_object"]).to eq("companies")
        expect(deal.company["target_record_id"]).to eq("rec_company456")
        expect(deal.company["attribute_type"]).to eq("record-reference")
        expect(deal.company["active_from"]).to be_a(String)
        expect(deal.company["created_by_actor"]).to be_a(Hash)
      end
    end

    describe "#owner" do
      it "returns the owner reference" do
        expect(deal.owner).to be_a(Hash)
        expect(deal.owner["referenced_actor_type"]).to eq("workspace-member")
        expect(deal.owner["referenced_actor_id"]).to eq("member_123")
        expect(deal.owner["attribute_type"]).to eq("actor-reference")
      end
    end
  end

  describe "status-based query methods" do
    describe ".in_stage" do
      before do
        stub_request(:post, "https://api.attio.com/v2/objects/deals/records/query")
          .with(
            body: {
              filter: {
                "$or": [
                  { stage: "Won 🎉" },
                  { stage: "Contract Signed" }
                ]
              }
            }.to_json,
            headers: {
              "Authorization" => "Bearer test_api_key",
              "Content-Type" => "application/json"
            }
          )
          .to_return(
            status: 200,
            body: {
              "data" => [deal_data]
            }.to_json,
            headers: {"Content-Type" => "application/json"}
          )
      end

      it "queries deals by multiple stage names" do
        results = described_class.in_stage(stage_names: ["Won 🎉", "Contract Signed"])
        expect(results).to be_a(Attio::APIResource::ListObject)
        expect(results.first).to be_a(described_class)
      end
    end

    describe ".won" do
      before do
        stub_request(:post, "https://api.attio.com/v2/objects/deals/records/query")
          .with(
            body: {
              filter: {
                stage: "Won 🎉"
              }
            }.to_json,
            headers: {
              "Authorization" => "Bearer test_api_key",
              "Content-Type" => "application/json"
            }
          )
          .to_return(
            status: 200,
            body: {
              "data" => [deal_data.merge(
                "values" => deal_data["values"].merge(
                  "stage" => [{
                    "status" => {
                      "title" => "Won 🎉",
                      "is_archived" => false
                    },
                    "attribute_type" => "status"
                  }]
                )
              )]
            }.to_json,
            headers: {"Content-Type" => "application/json"}
          )
      end

      it "finds won deals using configuration" do
        results = described_class.won
        expect(results).to be_a(Attio::APIResource::ListObject)
        expect(results.first[:stage]["status"]["title"]).to eq("Won 🎉")
      end
    end

    describe ".lost" do
      before do
        stub_request(:post, "https://api.attio.com/v2/objects/deals/records/query")
          .with(
            body: {
              filter: {
                stage: "Lost"
              }
            }.to_json,
            headers: {
              "Authorization" => "Bearer test_api_key",
              "Content-Type" => "application/json"
            }
          )
          .to_return(
            status: 200,
            body: {
              "data" => [deal_data.merge(
                "values" => deal_data["values"].merge(
                  "stage" => [{
                    "status" => {
                      "title" => "Lost",
                      "is_archived" => false
                    },
                    "attribute_type" => "status"
                  }]
                )
              )]
            }.to_json,
            headers: {"Content-Type" => "application/json"}
          )
      end

      it "finds lost deals using configuration" do
        results = described_class.lost
        expect(results).to be_a(Attio::APIResource::ListObject)
        expect(results.first[:stage]["status"]["title"]).to eq("Lost")
      end
    end

    describe ".open_deals" do
      before do
        stub_request(:post, "https://api.attio.com/v2/objects/deals/records/query")
          .with(
            body: {
              filter: {
                "$or": [
                  { stage: "Lead" },
                  { stage: "In Progress" }
                ]
              }
            }.to_json,
            headers: {
              "Authorization" => "Bearer test_api_key",
              "Content-Type" => "application/json"
            }
          )
          .to_return(
            status: 200,
            body: {
              "data" => [deal_data]
            }.to_json,
            headers: {"Content-Type" => "application/json"}
          )
      end

      it "finds open deals (lead + in progress) using configuration" do
        results = described_class.open_deals
        expect(results).to be_a(Attio::APIResource::ListObject)
        expect(results.first).to be_a(described_class)
      end
    end

    describe "with custom configuration" do
      before do
        # Set custom configuration (this runs after the spec_helper's before block)
        Attio.configuration.won_statuses = ["Customer Won", "Deal Closed"]
        Attio.configuration.lost_statuses = ["No Budget", "Competitor Won"]
        
        stub_request(:post, "https://api.attio.com/v2/objects/deals/records/query")
          .with(
            body: {
              filter: {
                "$or": [
                  { stage: "Customer Won" },
                  { stage: "Deal Closed" }
                ]
              }
            }.to_json,
            headers: {
              "Authorization" => "Bearer test_api_key",
              "Content-Type" => "application/json"
            }
          )
          .to_return(
            status: 200,
            body: {
              "data" => [deal_data]
            }.to_json,
            headers: {"Content-Type" => "application/json"}
          )
      end

      it "uses custom configured statuses for queries" do
        results = described_class.won
        expect(results).to be_a(Attio::APIResource::ListObject)
      end
    end
  end

  describe "search methods" do
    describe ".find_by" do
      before do
        stub_request(:post, "https://api.attio.com/v2/objects/deals/records/query")
          .with(
            body: {
              filter: {
                "$and": [
                  {"stage": "won"},
                  {"company": {
                    "target_object": "companies",
                    "target_record_id": "rec_company123"
                  }}
                ]
              }
            }.to_json,
            headers: {
              "Authorization" => "Bearer test_api_key",
              "Content-Type" => "application/json"
            }
          )
          .to_return(
            status: 200,
            body: {
              "data" => [deal_data]
            }.to_json,
            headers: {"Content-Type" => "application/json"}
          )
      end

      it "finds deals by status and company" do
        result = described_class.find_by(
          status: "won",
          company: {
            "target_object" => "companies",
            "target_record_id" => "rec_company123"
          }
        )

        expect(result).to be_a(described_class)
        expect(result[:name]).to eq("Enterprise Deal")
      end
    end

    describe ".find_by_status" do
      before do
        stub_request(:post, "https://api.attio.com/v2/objects/deals/records/query")
          .with(
            body: {
              filter: {"stage": "open"}
            }.to_json,
            headers: {
              "Authorization" => "Bearer test_api_key",
              "Content-Type" => "application/json"
            }
          )
          .to_return(
            status: 200,
            body: {
              "data" => [deal_data]
            }.to_json,
            headers: {"Content-Type" => "application/json"}
          )
      end

      it "finds deals by status using convenience method" do
        result = described_class.find_by(status: "open")
        expect(result).to be_a(described_class)
      end
    end

    describe ".find_by_value_range" do
      before do
        stub_request(:post, "https://api.attio.com/v2/objects/deals/records/query")
          .with(
            body: {
              filter: {
                "$and": [
                  {"value": {"$gte": 100000}},
                  {"value": {"$lte": 500000}}
                ]
              }
            }.to_json,
            headers: {
              "Authorization" => "Bearer test_api_key",
              "Content-Type" => "application/json"
            }
          )
          .to_return(
            status: 200,
            body: {
              "data" => [deal_data]
            }.to_json,
            headers: {"Content-Type" => "application/json"}
          )
      end

      it "finds deals within a value range" do
        results = described_class.find_by_value_range(min: 100000, max: 500000)
        expect(results).to be_a(Attio::APIResource::ListObject)
        expect(results.first).to be_a(described_class)
      end
    end
  end

  describe "update methods" do
    let(:deal) { described_class.new(deal_data) }

    describe "#update_status" do
      before do
        stub_request(:put, "https://api.attio.com/v2/objects/deals/records/rec_deal123")
          .with(
            body: {
              data: {
                values: {
                  stage: "Won 🎉"
                }
              }
            }.to_json,
            headers: {
              "Authorization" => "Bearer test_api_key",
              "Content-Type" => "application/json"
            }
          )
          .to_return(
            status: 200,
            body: {"data" => deal_data.merge(
              "values" => deal_data["values"].merge(
                "stage" => [{
                  "status" => {
                    "title" => "Won 🎉",
                    "is_archived" => false
                  },
                  "attribute_type" => "status"
                }]
              )
            )}.to_json,
            headers: {"Content-Type" => "application/json"}
          )
      end

      it "updates the deal status" do
        updated = deal.update_status("Won 🎉")
        expect(updated).to be_a(described_class)
        expect(updated[:stage]).to be_a(Hash)
        expect(updated[:stage]["status"]["title"]).to eq("Won 🎉")
      end
    end

    # update_probability is commented out since probability attribute may not exist
  end

  describe "associations" do
    let(:deal) { described_class.new(deal_data) }

    describe "#company_record" do
      before do
        company_data = {
          "id" => {"object_id" => "obj_companies", "record_id" => "rec_company456"},
          "values" => {
            "name" => "Acme Corp"
          }
        }

        stub_request(:get, "https://api.attio.com/v2/objects/companies/records/rec_company456")
          .with(
            headers: {
              "Authorization" => "Bearer test_api_key",
              "Content-Type" => "application/json"
            }
          )
          .to_return(
            status: 200,
            body: {"data" => company_data}.to_json,
            headers: {"Content-Type" => "application/json"}
          )
      end

      it "fetches the associated company" do
        company = deal.company_record
        expect(company).to be_a(Attio::Company)
        expect(company[:name]).to eq("Acme Corp")
      end
    end
  end
end