# frozen_string_literal: true

require "spec_helper"
require_relative "integration_helper"

RSpec.describe "Deal status methods", :integration do
  describe ".in_stage" do
    it "queries deals by stage names" do
      # This should query for deals with specific stages
      results = Attio::Deal.in_stage(stage_names: ["Won 🎉"])
      
      expect(results).to be_a(Attio::APIResource::ListObject)
      results.each do |deal|
        expect(deal).to be_a(Attio::Deal)
      end
    end

    it "accepts multiple stage names" do
      results = Attio::Deal.in_stage(stage_names: ["Lead", "In Progress"])
      
      expect(results).to be_a(Attio::APIResource::ListObject)
    end
  end

  describe ".won" do
    it "returns deals with won status using default configuration" do
      results = Attio::Deal.won
      
      expect(results).to be_a(Attio::APIResource::ListObject)
      results.each do |deal|
        expect(deal).to be_a(Attio::Deal)
        # Check that the deal's stage is actually "Won 🎉"
        if deal.stage.is_a?(Hash)
          stage_title = deal.stage.dig("status", "title")
        else
          stage_title = deal.stage
        end
        expect(["Won 🎉"]).to include(stage_title) if stage_title
      end
    end
  end

  describe ".lost" do
    it "returns deals with lost status using default configuration" do
      results = Attio::Deal.lost
      
      expect(results).to be_a(Attio::APIResource::ListObject)
      results.each do |deal|
        expect(deal).to be_a(Attio::Deal)
        # Check that the deal's stage is actually "Lost"
        if deal.stage.is_a?(Hash)
          stage_title = deal.stage.dig("status", "title")
        else
          stage_title = deal.stage
        end
        expect(["Lost"]).to include(stage_title) if stage_title
      end
    end
  end

  describe ".open_deals" do
    it "returns deals with open statuses (Lead and In Progress)" do
      results = Attio::Deal.open_deals
      
      expect(results).to be_a(Attio::APIResource::ListObject)
      results.each do |deal|
        expect(deal).to be_a(Attio::Deal)
        # Check that the deal's stage is either "Lead" or "In Progress"
        if deal.stage.is_a?(Hash)
          stage_title = deal.stage.dig("status", "title")
        else
          stage_title = deal.stage
        end
        expect(["Lead", "In Progress"]).to include(stage_title) if stage_title
      end
    end
  end

  describe "with custom configuration" do
    around do |example|
      # Save original configuration
      original_won = Attio.configuration.won_statuses
      original_lost = Attio.configuration.lost_statuses
      
      # Set custom configuration
      Attio.configuration.won_statuses = ["Won 🎉", "Contract Signed"]
      Attio.configuration.lost_statuses = ["Lost", "No Budget"]
      
      example.run
      
      # Restore original configuration
      Attio.configuration.won_statuses = original_won
      Attio.configuration.lost_statuses = original_lost
    end

    it "uses custom configured statuses for .won queries" do
      results = Attio::Deal.won
      
      expect(results).to be_a(Attio::APIResource::ListObject)
      # The query should be looking for deals with either "Won 🎉" or "Contract Signed"
      # We can't verify the actual statuses without real data, but we can verify the query runs
    end
  end
end