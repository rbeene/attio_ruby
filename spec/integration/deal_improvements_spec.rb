# frozen_string_literal: true

require "spec_helper"
require_relative "integration_helper"

RSpec.describe "Deal Improvements", :integration do
  let(:owner_email) { ENV["ATTIO_TEST_USER_EMAIL"] }
  let(:unique_id) { "#{Time.now.to_i}-#{rand(10000)}" }

  before do
    skip "Set ATTIO_TEST_USER_EMAIL env var to run Deal tests" unless owner_email
  end

  describe "Monetary value improvements" do
    let(:deal) do
      Attio::Deal.create(
        name: "Value Test #{unique_id}",
        value: 75000,
        stage: "In Progress",
        owner: owner_email
      )
    end

    after do
      deal&.destroy
    end

    describe "#amount" do
      it "returns the monetary amount as a float" do
        expect(deal.amount).to eq(75000.0)
      end
    end

    describe "#currency" do
      it "returns the currency code" do
        expect(deal.currency).to eq("USD")
      end
    end

    describe "#formatted_amount" do
      it "returns a formatted currency string" do
        expect(deal.formatted_amount).to eq("$75,000.00")
      end
    end

    describe "#raw_value" do
      it "returns the raw value hash from the API" do
        raw = deal.raw_value
        expect(raw).to be_a(Hash)
        expect(raw["currency_value"]).to eq(75000)
        expect(raw["currency_code"]).to eq("USD")
      end
    end
  end

  describe "Stage normalization" do
    let(:deal) do
      Attio::Deal.create(
        name: "Stage Test #{unique_id}",
        value: 50000,
        stage: "Won 🎉",
        owner: owner_email
      )
    end

    after do
      deal&.destroy
    end

    describe "#stage" do
      it "returns the normalized stage title" do
        expect(deal.stage).to eq("Won 🎉")
      end
    end

    describe "#current_status" do
      it "delegates to stage method" do
        expect(deal.current_status).to eq(deal.stage)
      end
    end
  end

  describe "Deal categorization methods" do
    describe "size categories" do
      it "correctly categorizes enterprise deals" do
        deal = Attio::Deal.create(
          name: "Enterprise #{unique_id}",
          value: 150000,
          stage: "Lead",
          owner: owner_email
        )

        expect(deal.enterprise?).to be true
        expect(deal.mid_market?).to be false
        expect(deal.small?).to be false
        expect(deal.size_category).to eq(:enterprise)

        deal.destroy
      end

      it "correctly categorizes mid-market deals" do
        deal = Attio::Deal.create(
          name: "Mid-Market #{unique_id}",
          value: 50000,
          stage: "Lead",
          owner: owner_email
        )

        expect(deal.enterprise?).to be false
        expect(deal.mid_market?).to be true
        expect(deal.small?).to be false
        expect(deal.size_category).to eq(:mid_market)

        deal.destroy
      end

      it "correctly categorizes small deals" do
        deal = Attio::Deal.create(
          name: "Small #{unique_id}",
          value: 5000,
          stage: "Lead",
          owner: owner_email
        )

        expect(deal.enterprise?).to be false
        expect(deal.mid_market?).to be false
        expect(deal.small?).to be true
        expect(deal.size_category).to eq(:small)

        deal.destroy
      end
    end
  end

  describe "Deal summary methods" do
    let(:deal) do
      Attio::Deal.create(
        name: "Summary Test #{unique_id}",
        value: 25000,
        stage: "In Progress",
        owner: owner_email
      )
    end

    after do
      deal&.destroy
    end

    describe "#summary" do
      it "returns a formatted summary string" do
        summary = deal.summary
        expect(summary).to include("Summary Test #{unique_id}")
        expect(summary).to include("$25,000")
        expect(summary).to include("In Progress")
      end
    end

    describe "#to_s" do
      it "returns the summary" do
        expect(deal.to_s).to eq(deal.summary)
      end
    end
  end

  describe "Class methods" do
    before do
      # Create test deals with different values
      @small_deal = Attio::Deal.create(
        name: "Small Deal #{unique_id}",
        value: 5000,
        stage: "Lead",
        owner: owner_email
      )

      @big_deal = Attio::Deal.create(
        name: "Big Deal #{unique_id}",
        value: 120000,
        stage: "In Progress",
        owner: owner_email
      )
    end

    after do
      @small_deal&.destroy
      @big_deal&.destroy
    end

    describe ".high_value" do
      it "filters deals above threshold" do
        high_value_deals = Attio::Deal.high_value(100_000)

        # Should include the big deal
        big_deal_names = high_value_deals.map(&:name)
        expect(big_deal_names).to include("Big Deal #{unique_id}")

        # All returned deals should have amount > 100,000
        high_value_deals.each do |deal|
          expect(deal.amount).to be > 100_000
        end
      end
    end

    describe ".recently_created" do
      it "returns deals created recently" do
        recent_deals = Attio::Deal.recently_created(1)

        # Should include our just-created deals
        recent_names = recent_deals.map(&:name)
        expect(recent_names).to include("Small Deal #{unique_id}")
        expect(recent_names).to include("Big Deal #{unique_id}")
      end
    end
  end

  describe "Status tracking methods" do
    let(:deal) do
      Attio::Deal.create(
        name: "Status Tracking #{unique_id}",
        value: 30000,
        stage: "In Progress",
        owner: owner_email
      )
    end

    after do
      deal&.destroy
    end

    describe "#days_in_stage" do
      it "returns a non-negative number" do
        days = deal.days_in_stage
        expect(days).to be >= 0
      end
    end

    describe "#stale?" do
      it "returns false for recently created deals" do
        # A just-created deal should not be stale
        expect(deal.stale?).to be false
      end
    end

    describe "#closed?" do
      it "returns false for open deals" do
        expect(deal.closed?).to be false
      end

      it "returns true for won deals" do
        # Update to won status
        updated = deal.update_stage("Won 🎉")
        expect(updated.closed?).to be true
      end
    end

    describe "#needs_attention?" do
      it "returns false for recently created open deals" do
        expect(deal.needs_attention?).to be false
      end
    end
  end

  describe "Update value method improvements" do
    let(:deal) do
      Attio::Deal.create(
        name: "Update Value Test #{unique_id}",
        value: 10000,
        stage: "Lead",
        owner: owner_email
      )
    end

    after do
      deal&.destroy
    end

    describe "#update_value" do
      it "updates the deal value" do
        deal.update_value(20000)

        # Fetch fresh to verify update
        fresh_deal = Attio::Deal.retrieve(deal.id)
        expect(fresh_deal.amount).to eq(20000.0)
        expect(fresh_deal.currency).to eq("USD")
      end
    end
  end
end
