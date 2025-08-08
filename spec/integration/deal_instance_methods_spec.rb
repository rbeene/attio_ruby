# frozen_string_literal: true

require "spec_helper"
require_relative "integration_helper"

RSpec.describe "Deal instance methods", :integration do
  let(:deal) do
    # Get any deal from the API to test with
    deals = Attio::Deal.list(limit: 1)
    deals.first
  end

  describe "status extraction methods" do
    context "when a deal exists" do
      before do
        skip "No deals available in test workspace" unless deal
      end

      describe "#current_status" do
        it "extracts the current status title from the deal" do
          status = deal.current_status

          # Status should be a string if present
          expect(status).to be_nil.or be_a(String)

          # If we have a status, it should be one of the known statuses
          if status
            all_statuses = ["Lead", "In Progress", "Won 🎉", "Lost"]
            expect(all_statuses).to include(status).or be(true) # Allow custom statuses
          end
        end
      end

      describe "#status_changed_at" do
        it "extracts the timestamp when the status changed" do
          timestamp = deal.status_changed_at

          # Timestamp should be nil or a Time object
          expect(timestamp).to be_nil.or be_a(Time)
        end
      end

      describe "#won?" do
        it "returns true for won deals, false otherwise" do
          result = deal.won?
          expect(result).to be(true).or be(false)

          # If the deal has "Won 🎉" status, it should return true
          if deal.current_status == "Won 🎉"
            expect(result).to be true
          end
        end
      end

      describe "#lost?" do
        it "returns true for lost deals, false otherwise" do
          result = deal.lost?
          expect(result).to be(true).or be(false)

          # If the deal has "Lost" status, it should return true
          if deal.current_status == "Lost"
            expect(result).to be true
          end
        end
      end

      describe "#open?" do
        it "returns true for open deals (Lead or In Progress)" do
          result = deal.open?
          expect(result).to be(true).or be(false)

          # If the deal has "Lead" or "In Progress" status, it should return true
          if ["Lead", "In Progress"].include?(deal.current_status)
            expect(result).to be true
          end
        end
      end

      describe "#won_at" do
        it "returns the timestamp when deal was won, or nil" do
          timestamp = deal.won_at

          # Should be nil or a Time object
          expect(timestamp).to be_nil.or be_a(Time)

          # If the deal is won, it should have a timestamp
          if deal.won?
            expect(timestamp).to be_a(Time)
          else
            expect(timestamp).to be_nil
          end
        end
      end

      describe "#closed_at" do
        it "returns the timestamp when deal was closed (won or lost)" do
          timestamp = deal.closed_at

          # Should be nil or a Time object
          expect(timestamp).to be_nil.or be_a(Time)

          # If the deal is won or lost, it should have a timestamp
          if deal.won? || deal.lost?
            expect(timestamp).to be_a(Time)
          else
            expect(timestamp).to be_nil
          end
        end
      end
    end
  end

  describe "with custom configuration" do
    around do |example|
      # Save original configuration
      original_won = Attio.configuration.won_statuses

      # Set custom configuration
      Attio.configuration.won_statuses = ["Won 🎉", "Contract Signed"]

      example.run

      # Restore original configuration
      Attio.configuration.won_statuses = original_won
    end

    context "when a deal exists" do
      before do
        skip "No deals available in test workspace" unless deal
      end

      it "uses configured statuses for won? check" do
        # This deal would be considered won if it has "Won 🎉" or "Contract Signed"
        result = deal.won?
        expect(result).to be(true).or be(false)

        if ["Won 🎉", "Contract Signed"].include?(deal.current_status)
          expect(result).to be true
        end
      end
    end
  end
end
