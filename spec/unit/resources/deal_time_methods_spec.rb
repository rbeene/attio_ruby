# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Attio::Deal time-based methods" do
  let(:deal_data) do
    {
      "id" => {"object_id" => "obj_deals", "record_id" => "rec_deal123"},
      "created_at" => Time.now.iso8601,
      "values" => {
        "name" => [{"value" => "Test Deal"}],
        "value" => [{
          "currency_code" => "USD",
          "currency_value" => 50000,
          "attribute_type" => "currency"
        }],
        "stage" => [{
          "active_from" => Time.now.iso8601,
          "status" => {"title" => "Won 🎉"},
          "attribute_type" => "status"
        }]
      }
    }
  end

  # Use fixed dates for consistent testing
  let(:fixed_today) { Date.new(2024, 6, 15) }
  let(:fixed_now) { Time.new(2024, 6, 15, 12, 0, 0) }

  before do
    allow(Date).to receive(:today).and_return(fixed_today)
    allow(Time).to receive(:now).and_return(fixed_now)
  end

  describe ".closed_in_period" do
    it "filters deals closed in a specific period" do
      q2_2024 = Attio::Util::TimePeriod.quarter(2024, 2)

      # Create deals with different closed dates
      deal_in_q2 = Attio::Deal.new(deal_data.merge(
        "values" => deal_data["values"].merge(
          "stage" => [{
            "active_from" => "2024-05-15T10:00:00Z",
            "status" => {"title" => "Won 🎉"},
            "attribute_type" => "status"
          }]
        )
      ))

      deal_in_q1 = Attio::Deal.new(deal_data.merge(
        "values" => deal_data["values"].merge(
          "stage" => [{
            "active_from" => "2024-02-15T10:00:00Z",
            "status" => {"title" => "Won 🎉"},
            "attribute_type" => "status"
          }]
        )
      ))

      # Mock the all method
      allow(Attio::Deal).to receive(:all).and_return([deal_in_q2, deal_in_q1])

      result = Attio::Deal.closed_in_period(q2_2024)
      expect(result).to contain_exactly(deal_in_q2)
    end
  end

  describe ".closed_in_quarter" do
    it "delegates to closed_in_period with correct quarter" do
      q2_period = instance_double(Attio::Util::TimePeriod)
      allow(Attio::Util::TimePeriod).to receive(:quarter).with(2024, 2).and_return(q2_period)

      expect(Attio::Deal).to receive(:closed_in_period).with(q2_period)

      Attio::Deal.closed_in_quarter(2024, 2)
    end
  end

  describe ".metrics_for_period" do
    it "calculates metrics for any time period" do
      period = Attio::Util::TimePeriod.last_30_days

      won_deal = Attio::Deal.new(deal_data.merge(
        "values" => deal_data["values"].merge(
          "stage" => [{
            "active_from" => (fixed_now - 5 * 24 * 60 * 60).iso8601,
            "status" => {"title" => "Won 🎉"},
            "attribute_type" => "status"
          }]
        )
      ))

      lost_deal = Attio::Deal.new(deal_data.merge(
        "values" => deal_data["values"].merge(
          "value" => [{"currency_value" => 30000}],
          "stage" => [{
            "active_from" => (fixed_now - 10 * 24 * 60 * 60).iso8601,
            "status" => {"title" => "Lost"},
            "attribute_type" => "status"
          }]
        )
      ))

      # Mock the list method with the expected filters
      won_list = double("ListObject", data: [won_deal])
      lost_list = double("ListObject", data: [lost_deal])

      allow(Attio::Deal).to receive(:list).and_return(won_list, lost_list)
      allow(period).to receive_messages(label: "Last 30 Days", includes?: true)

      metrics = Attio::Deal.metrics_for_period(period)

      expect(metrics[:period]).to eq("Last 30 Days")
      expect(metrics[:won_count]).to eq(1)
      expect(metrics[:won_amount]).to eq(50000.0)
      expect(metrics[:lost_count]).to eq(1)
      expect(metrics[:lost_amount]).to eq(30000.0)
      expect(metrics[:total_closed]).to eq(2)
      expect(metrics[:win_rate]).to eq(50.0)
    end
  end

  describe ".year_to_date_metrics" do
    it "returns metrics for year to date" do
      ytd_period = instance_double(Attio::Util::TimePeriod)
      allow(Attio::Util::TimePeriod).to receive(:year_to_date).and_return(ytd_period)

      expect(Attio::Deal).to receive(:metrics_for_period).with(ytd_period)

      Attio::Deal.year_to_date_metrics
    end
  end

  describe ".month_to_date_metrics" do
    it "returns metrics for month to date" do
      mtd_period = instance_double(Attio::Util::TimePeriod)
      allow(Attio::Util::TimePeriod).to receive(:month_to_date).and_return(mtd_period)

      expect(Attio::Deal).to receive(:metrics_for_period).with(mtd_period)

      Attio::Deal.month_to_date_metrics
    end
  end

  describe ".last_30_days_metrics" do
    it "returns metrics for last 30 days" do
      last_30_period = instance_double(Attio::Util::TimePeriod)
      allow(Attio::Util::TimePeriod).to receive(:last_30_days).and_return(last_30_period)

      expect(Attio::Deal).to receive(:metrics_for_period).with(last_30_period)

      Attio::Deal.last_30_days_metrics
    end
  end

  describe ".created_in_period" do
    it "filters deals created in a specific period" do
      # Create a real period object instead of mocking
      period = Attio::Util::TimePeriod.last_week

      # Create deal with created_at that's 2 days ago (within last week)
      recent_deal = Attio::Deal.new(deal_data.merge(
        "created_at" => (fixed_now - 2 * 24 * 60 * 60).iso8601
      ))

      # Create deal with created_at that's 10 days ago (outside last week)
      old_deal = Attio::Deal.new(deal_data.merge(
        "created_at" => (fixed_now - 10 * 24 * 60 * 60).iso8601
      ))

      allow(Attio::Deal).to receive(:all).and_return([recent_deal, old_deal])

      result = Attio::Deal.created_in_period(period)
      expect(result).to contain_exactly(recent_deal)
    end
  end

  describe ".recently_created" do
    it "delegates to created_in_period with last N days" do
      period = instance_double(Attio::Util::TimePeriod)
      allow(Attio::Util::TimePeriod).to receive(:last_days).with(7).and_return(period)

      expect(Attio::Deal).to receive(:created_in_period).with(period)

      Attio::Deal.recently_created(7)
    end

    it "defaults to 7 days" do
      period = instance_double(Attio::Util::TimePeriod)
      allow(Attio::Util::TimePeriod).to receive(:last_days).with(7).and_return(period)

      expect(Attio::Deal).to receive(:created_in_period).with(period)

      Attio::Deal.recently_created
    end
  end
end
