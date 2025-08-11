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

    describe "#amount" do
      it "returns the monetary amount as a float" do
        expect(deal.amount).to eq(150000.0)
      end

      it "handles currency_value correctly" do
        deal_with_numeric = described_class.new(deal_data.merge("values" => {"value" => [{"currency_value" => 75000}]}))
        expect(deal_with_numeric.amount).to eq(75000.0)
      end

      it "handles missing values" do
        deal_without_value = described_class.new(deal_data.merge("values" => {}))
        expect(deal_without_value.amount).to eq(0.0)
      end

      it "handles nil value field" do
        deal_with_nil = described_class.new(deal_data.merge("values" => {"value" => nil}))
        expect(deal_with_nil.amount).to eq(0.0)
      end
    end

    describe "#currency" do
      it "returns the currency code" do
        expect(deal.currency).to eq("USD")
      end

      it "defaults to USD when value is not a hash" do
        deal_with_numeric = described_class.new(deal_data.merge("values" => {"value" => [{"value" => 75000}]}))
        expect(deal_with_numeric.currency).to eq("USD")
      end
    end

    describe "#formatted_amount" do
      it "returns formatted currency string with decimals" do
        expect(deal.formatted_amount).to eq("$150,000.00")
      end

      it "handles smaller amounts with proper decimals" do
        small_deal = described_class.new(deal_data.merge("values" => {"value" => [{"currency_value" => 999.99}]}))
        expect(small_deal.formatted_amount).to eq("$999.99")
      end

      it "handles different currencies" do
        euro_deal = described_class.new(deal_data.merge("values" => {"value" => [{"currency_value" => 5000, "currency_code" => "EUR"}]}))
        expect(euro_deal.formatted_amount).to eq("€5,000.00")

        gbp_deal = described_class.new(deal_data.merge("values" => {"value" => [{"currency_value" => 1234.56, "currency_code" => "GBP"}]}))
        expect(gbp_deal.formatted_amount).to eq("£1,234.56")

        jpy_deal = described_class.new(deal_data.merge("values" => {"value" => [{"currency_value" => 100000, "currency_code" => "JPY"}]}))
        expect(jpy_deal.formatted_amount).to eq("¥100,000")
      end

      it "handles unknown currencies" do
        xyz_deal = described_class.new(deal_data.merge("values" => {"value" => [{"currency_value" => 1000, "currency_code" => "XYZ"}]}))
        expect(xyz_deal.formatted_amount).to eq("XYZ 1,000.00")
      end

      it "returns $0.00 for zero amounts" do
        zero_deal = described_class.new(deal_data.merge("values" => {}))
        expect(zero_deal.formatted_amount).to eq("$0.00")
      end
    end

    describe "#value (deprecated)" do
      it "returns amount with deprecation warning" do
        expect { deal.value }.to output(/DEPRECATION/).to_stderr
        expect(deal.value).to eq(150000.0)
      end
    end

    describe "#raw_value" do
      it "returns the raw value from API" do
        expect(deal.raw_value).to be_a(Hash)
        expect(deal.raw_value["currency_value"]).to eq(150000)
      end
    end

    describe "#stage" do
      it "normalizes and returns the stage title" do
        expect(deal.stage).to eq("negotiating")
      end

      it "handles missing stage" do
        no_stage_deal = described_class.new(deal_data.merge("values" => {}))
        expect(no_stage_deal.stage).to be_nil
      end

      it "handles nil stage" do
        nil_stage_deal = described_class.new(deal_data.merge("values" => {"stage" => nil}))
        expect(nil_stage_deal.stage).to be_nil
      end
    end

    describe "#status" do
      it "is an alias for stage" do
        expect(deal.status).to eq(deal.stage)
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

    describe "#enterprise?" do
      it "returns true for amounts > 100,000" do
        expect(deal.enterprise?).to be true
      end

      it "returns false for smaller amounts" do
        small_deal = described_class.new(deal_data.merge("values" => {"value" => [{"currency_value" => 50000}]}))
        expect(small_deal.enterprise?).to be false
      end
    end

    describe "#mid_market?" do
      it "returns true for amounts between 10,000 and 100,000" do
        mid_deal = described_class.new(deal_data.merge("values" => {"value" => [{"currency_value" => 50000}]}))
        expect(mid_deal.mid_market?).to be true
      end

      it "returns false for enterprise amounts" do
        expect(deal.mid_market?).to be false
      end
    end

    describe "#small?" do
      it "returns true for amounts < 10,000" do
        small_deal = described_class.new(deal_data.merge("values" => {"value" => [{"currency_value" => 5000}]}))
        expect(small_deal.small?).to be true
      end

      it "returns false for larger amounts" do
        expect(deal.small?).to be false
      end
    end

    describe "#size_category" do
      it "returns :enterprise for large deals" do
        expect(deal.size_category).to eq(:enterprise)
      end

      it "returns :mid_market for medium deals" do
        mid_deal = described_class.new(deal_data.merge("values" => {"value" => [{"currency_value" => 50000}]}))
        expect(mid_deal.size_category).to eq(:mid_market)
      end

      it "returns :small for small deals" do
        small_deal = described_class.new(deal_data.merge("values" => {"value" => [{"currency_value" => 5000}]}))
        expect(small_deal.size_category).to eq(:small)
      end
    end

    describe "#summary" do
      it "returns a formatted summary string" do
        expect(deal.summary).to eq("Enterprise Deal: $150,000.00 (negotiating)")
      end

      it "handles missing name" do
        unnamed_deal = described_class.new(deal_data.merge("values" => deal_data["values"].merge("name" => nil)))
        expect(unnamed_deal.summary).to eq("Unnamed Deal: $150,000.00 (negotiating)")
      end
    end

    describe "#to_s" do
      it "returns the summary" do
        expect(deal.to_s).to eq(deal.summary)
      end
    end

    describe "#status_changed_at" do
      it "extracts timestamp from stage active_from" do
        timestamp = deal.status_changed_at
        expect(timestamp).to be_a(Time)
      end

      it "returns nil when stage is not a hash" do
        simple_deal = described_class.new(deal_data.merge("values" => {"stage" => [{"value" => "Won 🎉"}]}))
        expect(simple_deal.status_changed_at).to be_nil
      end
    end

    describe "#won?" do
      it "returns true for won deals" do
        won_deal = described_class.new(deal_data.merge(
          "values" => deal_data["values"].merge(
            "stage" => [{
              "status" => {"title" => "Won 🎉"},
              "attribute_type" => "status"
            }]
          )
        ))
        expect(won_deal.won?).to be true
      end

      it "returns false for non-won deals" do
        expect(deal.won?).to be false
      end
    end

    describe "#lost?" do
      it "returns true for lost deals" do
        lost_deal = described_class.new(deal_data.merge(
          "values" => deal_data["values"].merge(
            "stage" => [{
              "status" => {"title" => "Lost"},
              "attribute_type" => "status"
            }]
          )
        ))
        expect(lost_deal.lost?).to be true
      end

      it "returns false for non-lost deals" do
        expect(deal.lost?).to be false
      end
    end

    describe "#closed?" do
      it "returns true for won or lost deals" do
        won_deal = described_class.new(deal_data.merge(
          "values" => deal_data["values"].merge(
            "stage" => [{
              "status" => {"title" => "Won 🎉"},
              "attribute_type" => "status"
            }]
          )
        ))
        expect(won_deal.closed?).to be true
      end

      it "returns false for open deals" do
        expect(deal.closed?).to be false
      end
    end

    describe "#days_in_stage" do
      it "calculates days since status change" do
        deal_with_old_status = described_class.new(deal_data.merge(
          "values" => deal_data["values"].merge(
            "stage" => [{
              "active_from" => (Time.now - (5 * 24 * 60 * 60)).iso8601,
              "status" => {"title" => "negotiating"},
              "attribute_type" => "status"
            }]
          )
        ))
        expect(deal_with_old_status.days_in_stage).to be_within(1).of(5)
      end

      it "returns 0 when no status change date" do
        simple_deal = described_class.new(deal_data.merge("values" => {"stage" => [{"value" => "Lead"}]}))
        expect(simple_deal.days_in_stage).to eq(0)
      end
    end

    describe "#stale?" do
      it "returns true for deals in stage too long" do
        old_deal = described_class.new(deal_data.merge(
          "values" => deal_data["values"].merge(
            "stage" => [{
              "active_from" => (Time.now - (35 * 24 * 60 * 60)).iso8601,
              "status" => {"title" => "negotiating"},
              "attribute_type" => "status"
            }]
          )
        ))
        expect(old_deal.stale?).to be true
      end

      it "returns false for closed deals" do
        won_deal = described_class.new(deal_data.merge(
          "values" => deal_data["values"].merge(
            "stage" => [{
              "active_from" => (Time.now - (60 * 24 * 60 * 60)).iso8601,
              "status" => {"title" => "Won 🎉"},
              "attribute_type" => "status"
            }]
          )
        ))
        expect(won_deal.stale?).to be false
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
                  {stage: "Won 🎉"},
                  {stage: "Contract Signed"}
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
                  {stage: "Lead"},
                  {stage: "In Progress"}
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
                  {stage: "Customer Won"},
                  {stage: "Deal Closed"}
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
                  {stage: "won"},
                  {company: {
                    target_object: "companies",
                    target_record_id: "rec_company123"
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
              filter: {stage: "open"}
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
                  {value: {"$gte": 100000}},
                  {value: {"$lte": 500000}}
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

  describe "class methods" do
    describe ".high_value" do
      it "filters deals above threshold" do
        deals = [
          described_class.new(deal_data),
          described_class.new(deal_data.merge("values" => {"value" => [{"currency_value" => 25000}]}))
        ]

        allow(described_class).to receive(:all).and_return(deals)

        high_value_deals = described_class.high_value(50_000)
        expect(high_value_deals.size).to eq(1)
        expect(high_value_deals.first.amount).to eq(150000.0)
      end
    end

    describe ".unassigned" do
      it "returns deals without owners" do
        deals = [
          described_class.new(deal_data),
          described_class.new(deal_data.merge("values" => {"owner" => nil}))
        ]

        allow(described_class).to receive(:all).and_return(deals)

        unassigned_deals = described_class.unassigned
        expect(unassigned_deals.size).to eq(1)
        expect(unassigned_deals.first.owner).to be_nil
      end
    end

    describe ".current_quarter_metrics" do
      it "calculates metrics for current quarter" do
        won_deal = described_class.new(deal_data.merge(
          "values" => deal_data["values"].merge(
            "stage" => [{
              "status" => {"title" => "Won 🎉"},
              "active_from" => Time.now.iso8601,
              "attribute_type" => "status"
            }]
          )
        ))

        # Mock the closed_at to be in current quarter
        allow(won_deal).to receive(:closed_at).and_return(Time.now)

        # Mock the list method to return ListObjects
        won_list = double("ListObject", data: [won_deal])
        lost_list = double("ListObject", data: [])

        allow(described_class).to receive(:list).and_return(won_list, lost_list)

        metrics = described_class.current_quarter_metrics
        expect(metrics[:won_count]).to eq(1)
        expect(metrics[:won_amount]).to eq(150000.0)
        expect(metrics[:win_rate]).to eq(100.0)
      end
    end
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
