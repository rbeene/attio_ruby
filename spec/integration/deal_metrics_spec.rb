# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Deal Metrics", :integration do
  let(:unique_id) { Time.now.to_i }
  let(:owner_email) { ENV["ATTIO_TEST_USER_EMAIL"] }

  before do
    skip "Skipping integration tests (RUN_INTEGRATION_TESTS not set)" unless ENV["RUN_INTEGRATION_TESTS"]
    skip "Cannot test without ATTIO_TEST_USER_EMAIL environment variable" unless ENV["ATTIO_TEST_USER_EMAIL"]
  end

  describe ".metrics_for_period" do
    it "calculates metrics for deals in different states" do
      created_deals = []

      begin
        # Create a won deal
        won_deal = Attio::Deal.create(
          name: "Won Deal #{unique_id}",
          value: 100_000,
          stage: "Won 🎉",
          owner: owner_email
        )
        created_deals << won_deal
        puts "\nCreated won deal: #{won_deal.name} - Amount: #{won_deal.formatted_amount}"

        # Create a lost deal
        lost_deal = Attio::Deal.create(
          name: "Lost Deal #{unique_id}",
          value: 50_000,
          stage: "Lost",
          owner: owner_email
        )
        created_deals << lost_deal
        puts "Created lost deal: #{lost_deal.name} - Amount: #{lost_deal.formatted_amount}"

        # Create an open deal (should not be included in metrics)
        open_deal = Attio::Deal.create(
          name: "Open Deal #{unique_id}",
          value: 75_000,
          stage: "Lead",
          owner: owner_email
        )
        created_deals << open_deal
        puts "Created open deal: #{open_deal.name} - Amount: #{open_deal.formatted_amount}"

        # Calculate metrics for the last 30 days (should include our new deals)
        puts "\n=== Calculating Metrics for Last 30 Days ==="
        metrics = Attio::Deal.last_30_days_metrics

        puts "Period: #{metrics[:period]}"
        puts "Won count: #{metrics[:won_count]} (total: #{metrics[:won_amount]})"
        puts "Lost count: #{metrics[:lost_count]} (total: #{metrics[:lost_amount]})"
        puts "Total closed: #{metrics[:total_closed]}"
        puts "Win rate: #{metrics[:win_rate]}%"

        # Verify the metrics include our deals
        expect(metrics[:period]).to eq("Last 30 Days")
        expect(metrics[:won_count]).to be >= 1
        expect(metrics[:lost_count]).to be >= 1
        expect(metrics[:total_closed]).to be >= 2
        expect(metrics[:win_rate]).to be_between(0, 100)

        # Test year-to-date metrics
        puts "\n=== Calculating Year-to-Date Metrics ==="
        ytd_metrics = Attio::Deal.year_to_date_metrics

        puts "Period: #{ytd_metrics[:period]}"
        puts "Won count: #{ytd_metrics[:won_count]} (total: #{ytd_metrics[:won_amount]})"
        puts "Lost count: #{ytd_metrics[:lost_count]} (total: #{ytd_metrics[:lost_amount]})"
        puts "Total closed: #{ytd_metrics[:total_closed]}"
        puts "Win rate: #{ytd_metrics[:win_rate]}%"

        expect(ytd_metrics[:period]).to eq("Year to Date")
        expect(ytd_metrics[:total_closed]).to be >= metrics[:total_closed]

        # Test current quarter metrics
        puts "\n=== Calculating Current Quarter Metrics ==="
        quarter_metrics = Attio::Deal.current_quarter_metrics

        current_quarter = (Date.today.month - 1) / 3 + 1
        expected_label = "Q#{current_quarter} #{Date.today.year}"

        puts "Period: #{quarter_metrics[:period]}"
        puts "Won count: #{quarter_metrics[:won_count]} (total: #{quarter_metrics[:won_amount]})"
        puts "Lost count: #{quarter_metrics[:lost_count]} (total: #{quarter_metrics[:lost_amount]})"
        puts "Total closed: #{quarter_metrics[:total_closed]}"
        puts "Win rate: #{quarter_metrics[:win_rate]}%"

        expect(quarter_metrics[:period]).to eq(expected_label)
      ensure
        # Clean up created deals
        puts "\n=== Cleaning up test deals ==="
        created_deals.each do |deal|
          deal.destroy
          puts "Deleted: #{deal.name}"
        rescue => e
          puts "Failed to delete #{deal.name}: #{e.message}"
        end
      end
    end
  end

  describe "Performance comparison" do
    it "demonstrates the efficiency of targeted API calls" do
      puts "\n=== Performance Comparison ==="

      # Time the new optimized approach
      start_time = Time.now
      metrics = Attio::Deal.last_30_days_metrics
      optimized_time = Time.now - start_time

      puts "Optimized approach (2 targeted API calls):"
      puts "  Time taken: #{(optimized_time * 1000).round(2)}ms"
      puts "  API calls made: 2 (won deals, lost deals)"
      puts "  Results: #{metrics[:total_closed]} closed deals found"

      # For comparison, let's also fetch all deals to show the difference
      start_time = Time.now
      all_deals = Attio::Deal.all(limit: 500)
      all_fetch_time = Time.now - start_time

      puts "\nComparison - fetching all deals:"
      puts "  Time taken: #{(all_fetch_time * 1000).round(2)}ms"
      puts "  API calls made: 1 (all deals)"
      puts "  Total deals fetched: #{all_deals.data.size}"
      puts "  Memory impact: Loaded #{all_deals.data.size} full deal objects"

      # The optimized approach should generally be faster for large datasets
      # and always uses less memory
      expect(metrics).to have_key(:won_count)
      expect(metrics).to have_key(:lost_count)
    end
  end

  describe "Edge cases" do
    it "handles periods with no deals gracefully" do
      # Test a future period that should have no deals
      future_period = Attio::Util::TimePeriod.between(
        Date.today + 365,
        Date.today + 395
      )

      metrics = Attio::Deal.metrics_for_period(future_period)

      expect(metrics[:won_count]).to eq(0)
      expect(metrics[:lost_count]).to eq(0)
      expect(metrics[:total_closed]).to eq(0)
      expect(metrics[:win_rate]).to eq(0.0)

      puts "\n=== Metrics for future period (should be empty) ==="
      puts "Period: #{metrics[:period]}"
      puts "Total closed: #{metrics[:total_closed]}"
      puts "Win rate: #{metrics[:win_rate]}%"
    end

    it "correctly filters deals by actual close date" do
      created_deals = []

      begin
        # Create a deal and immediately close it
        deal = Attio::Deal.create(
          name: "Quick Close Deal #{unique_id}",
          value: 25_000,
          stage: "Lead",
          owner: owner_email
        )
        created_deals << deal

        # Update to won status
        deal.update_stage("Won 🎉")

        # The deal should now appear in today's metrics
        today_period = Attio::Util::TimePeriod.between(Date.today, Date.today)
        today_metrics = Attio::Deal.metrics_for_period(today_period)

        puts "\n=== Today's Metrics ==="
        puts "Won today: #{today_metrics[:won_count]}"
        puts "Won amount today: #{today_metrics[:won_amount]}"

        # Should include our just-closed deal
        expect(today_metrics[:won_count]).to be >= 1
      ensure
        created_deals.each { |d|
          begin
            d.destroy
          rescue
            nil
          end
        }
      end
    end
  end
end
