# frozen_string_literal: true

require "spec_helper"
require "date"

RSpec.describe Attio::Util::TimePeriod do
  # Use a fixed "today" for all tests to ensure consistency
  let(:fixed_today) { Date.new(2024, 6, 15) } # June 15, 2024 (a Saturday in Q2)

  before do
    # Stub Date.today to return our fixed date
    allow(Date).to receive(:today).and_return(fixed_today)
  end

  describe ".year_to_date" do
    it "returns period from Jan 1 to today" do
      period = described_class.year_to_date
      expect(period.start_date).to eq(Date.new(2024, 1, 1))
      expect(period.end_date).to eq(fixed_today)
    end
  end

  describe ".month_to_date" do
    it "returns period from start of current month to today" do
      period = described_class.month_to_date
      expect(period.start_date).to eq(Date.new(2024, 6, 1))
      expect(period.end_date).to eq(fixed_today)
    end
  end

  describe ".quarter_to_date" do
    it "returns period from start of current quarter to today" do
      period = described_class.quarter_to_date
      expect(period.start_date).to eq(Date.new(2024, 4, 1)) # Q2 starts April 1
      expect(period.end_date).to eq(fixed_today)
    end
  end

  describe ".quarter" do
    it "returns the full quarter period" do
      # Q1 2024
      q1 = described_class.quarter(2024, 1)
      expect(q1.start_date).to eq(Date.new(2024, 1, 1))
      expect(q1.end_date).to eq(Date.new(2024, 3, 31))

      # Q2 2024
      q2 = described_class.quarter(2024, 2)
      expect(q2.start_date).to eq(Date.new(2024, 4, 1))
      expect(q2.end_date).to eq(Date.new(2024, 6, 30))

      # Q3 2024
      q3 = described_class.quarter(2024, 3)
      expect(q3.start_date).to eq(Date.new(2024, 7, 1))
      expect(q3.end_date).to eq(Date.new(2024, 9, 30))

      # Q4 2024
      q4 = described_class.quarter(2024, 4)
      expect(q4.start_date).to eq(Date.new(2024, 10, 1))
      expect(q4.end_date).to eq(Date.new(2024, 12, 31))
    end

    it "raises error for invalid quarter number" do
      expect { described_class.quarter(2024, 0) }.to raise_error(ArgumentError, "Quarter must be between 1 and 4")
      expect { described_class.quarter(2024, 5) }.to raise_error(ArgumentError, "Quarter must be between 1 and 4")
    end
  end

  describe ".current_quarter" do
    it "returns the full current quarter" do
      period = described_class.current_quarter
      expect(period.start_date).to eq(Date.new(2024, 4, 1))
      expect(period.end_date).to eq(Date.new(2024, 6, 30))
    end
  end

  describe ".previous_quarter" do
    context "when in Q2" do
      it "returns Q1 of same year" do
        period = described_class.previous_quarter
        expect(period.start_date).to eq(Date.new(2024, 1, 1))
        expect(period.end_date).to eq(Date.new(2024, 3, 31))
      end
    end

    context "when in Q1" do
      before do
        allow(Date).to receive(:today).and_return(Date.new(2024, 2, 15))
      end

      it "returns Q4 of previous year" do
        period = described_class.previous_quarter
        expect(period.start_date).to eq(Date.new(2023, 10, 1))
        expect(period.end_date).to eq(Date.new(2023, 12, 31))
      end
    end
  end

  describe ".month" do
    it "returns the full month period" do
      # January (31 days)
      jan = described_class.month(2024, 1)
      expect(jan.start_date).to eq(Date.new(2024, 1, 1))
      expect(jan.end_date).to eq(Date.new(2024, 1, 31))

      # February 2024 (leap year - 29 days)
      feb = described_class.month(2024, 2)
      expect(feb.start_date).to eq(Date.new(2024, 2, 1))
      expect(feb.end_date).to eq(Date.new(2024, 2, 29))

      # February 2023 (non-leap year - 28 days)
      feb_normal = described_class.month(2023, 2)
      expect(feb_normal.start_date).to eq(Date.new(2023, 2, 1))
      expect(feb_normal.end_date).to eq(Date.new(2023, 2, 28))

      # April (30 days)
      apr = described_class.month(2024, 4)
      expect(apr.start_date).to eq(Date.new(2024, 4, 1))
      expect(apr.end_date).to eq(Date.new(2024, 4, 30))
    end

    it "raises error for invalid month number" do
      expect { described_class.month(2024, 0) }.to raise_error(ArgumentError, "Month must be between 1 and 12")
      expect { described_class.month(2024, 13) }.to raise_error(ArgumentError, "Month must be between 1 and 12")
    end
  end

  describe ".current_month" do
    it "returns the full current month" do
      period = described_class.current_month
      expect(period.start_date).to eq(Date.new(2024, 6, 1))
      expect(period.end_date).to eq(Date.new(2024, 6, 30))
    end
  end

  describe ".previous_month" do
    context "when in June" do
      it "returns May of same year" do
        period = described_class.previous_month
        expect(period.start_date).to eq(Date.new(2024, 5, 1))
        expect(period.end_date).to eq(Date.new(2024, 5, 31))
      end
    end

    context "when in January" do
      before do
        allow(Date).to receive(:today).and_return(Date.new(2024, 1, 15))
      end

      it "returns December of previous year" do
        period = described_class.previous_month
        expect(period.start_date).to eq(Date.new(2023, 12, 1))
        expect(period.end_date).to eq(Date.new(2023, 12, 31))
      end
    end
  end

  describe ".year" do
    it "returns the full year period" do
      period = described_class.year(2024)
      expect(period.start_date).to eq(Date.new(2024, 1, 1))
      expect(period.end_date).to eq(Date.new(2024, 12, 31))
    end
  end

  describe ".current_year" do
    it "returns the full current year" do
      period = described_class.current_year
      expect(period.start_date).to eq(Date.new(2024, 1, 1))
      expect(period.end_date).to eq(Date.new(2024, 12, 31))
    end
  end

  describe ".previous_year" do
    it "returns the full previous year" do
      period = described_class.previous_year
      expect(period.start_date).to eq(Date.new(2023, 1, 1))
      expect(period.end_date).to eq(Date.new(2023, 12, 31))
    end
  end

  describe ".last_days" do
    it "returns the specified number of days including today" do
      period = described_class.last_days(7)
      expect(period.start_date).to eq(Date.new(2024, 6, 9))  # 7 days ago from June 15
      expect(period.end_date).to eq(fixed_today)
      expect(period.days).to eq(7)
    end

    it "handles month boundaries correctly" do
      period = described_class.last_days(30)
      expect(period.start_date).to eq(Date.new(2024, 5, 17))  # 30 days ago from June 15
      expect(period.end_date).to eq(fixed_today)
      expect(period.days).to eq(30)
    end
  end

  describe ".last_week" do
    it "returns the last 7 days" do
      period = described_class.last_week
      expect(period.start_date).to eq(Date.new(2024, 6, 9))
      expect(period.end_date).to eq(fixed_today)
      expect(period.days).to eq(7)
    end
  end

  describe ".last_30_days" do
    it "returns the last 30 days" do
      period = described_class.last_30_days
      expect(period.start_date).to eq(Date.new(2024, 5, 17))
      expect(period.end_date).to eq(fixed_today)
      expect(period.days).to eq(30)
    end
  end

  describe ".last_90_days" do
    it "returns the last 90 days" do
      period = described_class.last_90_days
      expect(period.start_date).to eq(Date.new(2024, 3, 18))
      expect(period.end_date).to eq(fixed_today)
      expect(period.days).to eq(90)
    end
  end

  describe ".last_year_rolling" do
    it "returns the last 365 days including today" do
      period = described_class.last_year_rolling
      # 365 days including today means we go back 364 days from today
      # June 15, 2024 - 364 days = June 17, 2023
      expect(period.start_date).to eq(Date.new(2023, 6, 17))
      expect(period.end_date).to eq(fixed_today)
      expect(period.days).to eq(365)
    end
  end

  describe ".between" do
    it "creates a custom period between two dates" do
      start_date = Date.new(2024, 3, 1)
      end_date = Date.new(2024, 5, 31)
      period = described_class.between(start_date, end_date)

      expect(period.start_date).to eq(start_date)
      expect(period.end_date).to eq(end_date)
    end

    it "accepts string dates" do
      period = described_class.between("2024-03-01", "2024-05-31")
      expect(period.start_date).to eq(Date.new(2024, 3, 1))
      expect(period.end_date).to eq(Date.new(2024, 5, 31))
    end
  end

  describe "#includes?" do
    let(:period) { described_class.quarter(2024, 2) } # Q2 2024

    it "returns true for dates within the period" do
      expect(period.includes?(Date.new(2024, 4, 1))).to be true   # First day
      expect(period.includes?(Date.new(2024, 5, 15))).to be true  # Middle
      expect(period.includes?(Date.new(2024, 6, 30))).to be true  # Last day
    end

    it "returns false for dates outside the period" do
      expect(period.includes?(Date.new(2024, 3, 31))).to be false # Day before
      expect(period.includes?(Date.new(2024, 7, 1))).to be false  # Day after
      expect(period.includes?(Date.new(2023, 5, 15))).to be false # Wrong year
    end

    it "accepts Time objects" do
      expect(period.includes?(Time.new(2024, 5, 15, 12, 30))).to be true
    end

    it "accepts DateTime objects" do
      expect(period.includes?(DateTime.new(2024, 5, 15))).to be true
    end
  end

  describe "#to_range" do
    it "returns a Range object" do
      period = described_class.month(2024, 6)
      range = period.to_range

      expect(range).to be_a(Range)
      expect(range.first).to eq(Date.new(2024, 6, 1))
      expect(range.last).to eq(Date.new(2024, 6, 30))
    end
  end

  describe "#days" do
    it "returns the number of days in the period" do
      expect(described_class.month(2024, 1).days).to eq(31)
      expect(described_class.month(2024, 2).days).to eq(29) # Leap year
      expect(described_class.month(2023, 2).days).to eq(28) # Non-leap year
      expect(described_class.quarter(2024, 1).days).to eq(91) # Q1 in leap year
      expect(described_class.year(2024).days).to eq(366) # Leap year
      expect(described_class.year(2023).days).to eq(365) # Normal year
    end
  end

  describe "#to_s" do
    it "returns date range as string" do
      period = described_class.quarter(2024, 2)
      expect(period.to_s).to eq("2024-04-01 to 2024-06-30")
    end

    it "returns single date for one-day periods" do
      period = described_class.between(Date.new(2024, 6, 15), Date.new(2024, 6, 15))
      expect(period.to_s).to eq("2024-06-15")
    end
  end

  describe "#label" do
    context "with recognized patterns" do
      it "returns 'Year to Date' for YTD periods" do
        period = described_class.year_to_date
        expect(period.label).to eq("Year to Date")
      end

      it "returns 'Month to Date' for MTD periods" do
        period = described_class.month_to_date
        expect(period.label).to eq("Month to Date")
      end

      it "returns year for full year periods" do
        period = described_class.year(2024)
        expect(period.label).to eq("2024")
      end

      it "returns month name and year for full month periods" do
        period = described_class.month(2024, 6)
        expect(period.label).to eq("June 2024")
      end

      it "returns quarter label for full quarter periods" do
        period = described_class.quarter(2024, 2)
        expect(period.label).to eq("Q2 2024")
      end

      it "returns 'Last 7 Days' for last week" do
        period = described_class.last_week
        expect(period.label).to eq("Last 7 Days")
      end

      it "returns 'Last 30 Days' for last 30 days" do
        period = described_class.last_30_days
        expect(period.label).to eq("Last 30 Days")
      end

      it "returns 'Last 90 Days' for last 90 days" do
        period = described_class.last_90_days
        expect(period.label).to eq("Last 90 Days")
      end
    end

    context "with custom periods" do
      it "returns date range for unrecognized patterns" do
        period = described_class.between(Date.new(2024, 3, 15), Date.new(2024, 5, 20))
        expect(period.label).to eq("2024-03-15 to 2024-05-20")
      end
    end
  end

  describe "edge cases" do
    context "leap year handling" do
      it "correctly handles February 29 in leap years" do
        period = described_class.month(2024, 2)
        expect(period.end_date).to eq(Date.new(2024, 2, 29))
        expect(period.includes?(Date.new(2024, 2, 29))).to be true
      end

      it "correctly handles February 28 in non-leap years" do
        period = described_class.month(2023, 2)
        expect(period.end_date).to eq(Date.new(2023, 2, 28))
        expect(period.includes?(Date.new(2023, 2, 28))).to be true
      end
    end

    context "year boundaries" do
      before do
        # Test around New Year's Eve/Day
        allow(Date).to receive(:today).and_return(Date.new(2024, 1, 2))
      end

      it "handles last_days across year boundary" do
        period = described_class.last_days(7)
        expect(period.start_date).to eq(Date.new(2023, 12, 27))
        expect(period.end_date).to eq(Date.new(2024, 1, 2))
      end

      it "handles YTD at start of year" do
        period = described_class.year_to_date
        expect(period.start_date).to eq(Date.new(2024, 1, 1))
        expect(period.end_date).to eq(Date.new(2024, 1, 2))
        expect(period.days).to eq(2)
      end
    end

    context "month boundaries" do
      it "handles varying month lengths correctly" do
        # 31-day months
        expect(described_class.month(2024, 1).days).to eq(31)
        expect(described_class.month(2024, 3).days).to eq(31)
        expect(described_class.month(2024, 5).days).to eq(31)
        expect(described_class.month(2024, 7).days).to eq(31)
        expect(described_class.month(2024, 8).days).to eq(31)
        expect(described_class.month(2024, 10).days).to eq(31)
        expect(described_class.month(2024, 12).days).to eq(31)

        # 30-day months
        expect(described_class.month(2024, 4).days).to eq(30)
        expect(described_class.month(2024, 6).days).to eq(30)
        expect(described_class.month(2024, 9).days).to eq(30)
        expect(described_class.month(2024, 11).days).to eq(30)
      end
    end
  end
end
