# frozen_string_literal: true

require "spec_helper"
require "attio/concerns/time_filterable"

RSpec.describe Attio::Concerns::TimeFilterable do
  # Create a test class that includes the module
  let(:test_class) do
    Class.new do
      include Attio::Concerns::TimeFilterable
      
      attr_accessor :created_at, :updated_at
      
      # Minimal implementation for testing
      def self.all(**opts)
        @records || []
      end
      
      def self.set_records(records)
        @records = records
      end
      
      def [](key)
        @attributes ||= {}
        @attributes[key]
      end
      
      def []=(key, value)
        @attributes ||= {}
        @attributes[key] = value
        # Also set accessor if it's created_at or updated_at
        if key == :created_at
          @created_at = value
        elsif key == :updated_at
          @updated_at = value
        end
      end
    end
  end
  
  # Use fixed dates for consistent testing
  let(:fixed_today) { Date.new(2024, 6, 15) }
  let(:fixed_now) { Time.new(2024, 6, 15, 12, 0, 0) }
  
  before do
    allow(Date).to receive(:today).and_return(fixed_today)
    allow(Time).to receive(:now).and_return(fixed_now)
  end
  
  describe "class methods" do
    describe ".in_period" do
      it "filters records by date field within period" do
        period = Attio::Util::TimePeriod.last_days(7)
        
        recent = test_class.new
        recent[:created_at] = (fixed_now - 2 * 24 * 60 * 60).iso8601
        
        old = test_class.new
        old[:created_at] = (fixed_now - 10 * 24 * 60 * 60).iso8601
        
        test_class.set_records([recent, old])
        
        result = test_class.in_period(period, date_field: :created_at)
        expect(result).to contain_exactly(recent)
      end
      
      it "handles different date formats" do
        period = Attio::Util::TimePeriod.current_month
        
        string_date = test_class.new
        string_date[:created_at] = "2024-06-10T10:00:00Z"
        
        time_date = test_class.new
        time_date[:created_at] = Time.new(2024, 6, 5, 10, 0, 0)
        
        test_class.set_records([string_date, time_date])
        
        result = test_class.in_period(period, date_field: :created_at)
        expect(result).to contain_exactly(string_date, time_date)
      end
      
      it "skips records with nil dates" do
        period = Attio::Util::TimePeriod.last_days(7)
        
        with_date = test_class.new
        with_date[:created_at] = fixed_now.iso8601
        
        without_date = test_class.new
        without_date[:created_at] = nil
        
        test_class.set_records([with_date, without_date])
        
        result = test_class.in_period(period, date_field: :created_at)
        expect(result).to contain_exactly(with_date)
      end
    end
    
    describe ".recently_created" do
      it "returns records created in last N days" do
        recent = test_class.new
        recent[:created_at] = (fixed_now - 3 * 24 * 60 * 60).iso8601
        
        old = test_class.new
        old[:created_at] = (fixed_now - 10 * 24 * 60 * 60).iso8601
        
        test_class.set_records([recent, old])
        
        result = test_class.recently_created(7)
        expect(result).to contain_exactly(recent)
      end
      
      it "defaults to 7 days" do
        expect(test_class).to receive(:in_period).with(
          an_instance_of(Attio::Util::TimePeriod),
          date_field: :created_at
        )
        
        test_class.recently_created
      end
    end
    
    describe ".recently_updated" do
      it "filters by updated_at field" do
        recent = test_class.new
        recent[:updated_at] = (fixed_now - 2 * 24 * 60 * 60).iso8601
        
        old = test_class.new
        old[:updated_at] = (fixed_now - 10 * 24 * 60 * 60).iso8601
        
        test_class.set_records([recent, old])
        
        result = test_class.recently_updated(5)
        expect(result).to contain_exactly(recent)
      end
    end
    
    describe ".created_this_year" do
      it "returns records created in current year" do
        this_year = test_class.new
        this_year[:created_at] = "2024-03-15T10:00:00Z"
        
        last_year = test_class.new
        last_year[:created_at] = "2023-12-15T10:00:00Z"
        
        test_class.set_records([this_year, last_year])
        
        result = test_class.created_this_year
        expect(result).to contain_exactly(this_year)
      end
    end
    
    describe ".created_this_month" do
      it "returns records created in current month" do
        this_month = test_class.new
        this_month[:created_at] = "2024-06-10T10:00:00Z"
        
        last_month = test_class.new
        last_month[:created_at] = "2024-05-10T10:00:00Z"
        
        test_class.set_records([this_month, last_month])
        
        result = test_class.created_this_month
        expect(result).to contain_exactly(this_month)
      end
    end
    
    describe ".created_year_to_date" do
      it "returns records created from Jan 1 to today" do
        ytd = test_class.new
        ytd[:created_at] = "2024-04-10T10:00:00Z"
        
        last_year = test_class.new
        last_year[:created_at] = "2023-12-31T23:59:59Z"
        
        test_class.set_records([ytd, last_year])
        
        result = test_class.created_year_to_date
        expect(result).to contain_exactly(ytd)
      end
    end
    
    describe ".created_in_month" do
      it "returns records created in specific month" do
        march = test_class.new
        march[:created_at] = "2024-03-15T10:00:00Z"
        
        april = test_class.new
        april[:created_at] = "2024-04-15T10:00:00Z"
        
        test_class.set_records([march, april])
        
        result = test_class.created_in_month(2024, 3)
        expect(result).to contain_exactly(march)
      end
    end
    
    describe ".created_in_quarter" do
      it "returns records created in specific quarter" do
        q1 = test_class.new
        q1[:created_at] = "2024-02-15T10:00:00Z"
        
        q2 = test_class.new
        q2[:created_at] = "2024-05-15T10:00:00Z"
        
        test_class.set_records([q1, q2])
        
        result = test_class.created_in_quarter(2024, 1)
        expect(result).to contain_exactly(q1)
      end
    end
    
    describe ".created_in_year" do
      it "returns records created in specific year" do
        year_2023 = test_class.new
        year_2023[:created_at] = "2023-06-15T10:00:00Z"
        
        year_2024 = test_class.new
        year_2024[:created_at] = "2024-06-15T10:00:00Z"
        
        test_class.set_records([year_2023, year_2024])
        
        result = test_class.created_in_year(2023)
        expect(result).to contain_exactly(year_2023)
      end
    end
    
    describe ".activity_metrics" do
      it "calculates activity metrics for a period" do
        period = Attio::Util::TimePeriod.last_30_days
        
        created_recently = test_class.new
        created_recently[:created_at] = (fixed_now - 5 * 24 * 60 * 60).iso8601
        created_recently[:updated_at] = (fixed_now - 1 * 24 * 60 * 60).iso8601
        
        updated_recently = test_class.new
        updated_recently[:created_at] = (fixed_now - 60 * 24 * 60 * 60).iso8601
        updated_recently[:updated_at] = (fixed_now - 2 * 24 * 60 * 60).iso8601
        
        old = test_class.new
        old[:created_at] = (fixed_now - 60 * 24 * 60 * 60).iso8601
        old[:updated_at] = (fixed_now - 45 * 24 * 60 * 60).iso8601
        
        test_class.set_records([created_recently, updated_recently, old])
        
        metrics = test_class.activity_metrics(period)
        
        expect(metrics[:period]).to eq("Last 30 Days")
        expect(metrics[:created_count]).to eq(1)
        expect(metrics[:updated_count]).to eq(2)
        expect(metrics[:total_activity]).to eq(2)
      end
    end
  end
  
  describe "instance methods" do
    let(:record) { test_class.new }
    
    describe "#created_in?" do
      it "returns true if created in period" do
        period = Attio::Util::TimePeriod.current_month
        record[:created_at] = "2024-06-10T10:00:00Z"
        
        expect(record.created_in?(period)).to be true
      end
      
      it "returns false if not created in period" do
        period = Attio::Util::TimePeriod.current_month
        record[:created_at] = "2024-05-10T10:00:00Z"
        
        expect(record.created_in?(period)).to be false
      end
      
      it "returns false if no created_at" do
        period = Attio::Util::TimePeriod.current_month
        record[:created_at] = nil
        
        expect(record.created_in?(period)).to be false
      end
    end
    
    describe "#updated_in?" do
      it "checks updated_at field" do
        period = Attio::Util::TimePeriod.last_week
        record[:updated_at] = (fixed_now - 3 * 24 * 60 * 60).iso8601
        
        expect(record.updated_in?(period)).to be true
      end
    end
    
    describe "#age_in_days" do
      it "calculates days since creation" do
        record[:created_at] = (fixed_now - 10 * 24 * 60 * 60).iso8601
        expect(record.age_in_days).to eq(10)
      end
      
      it "returns nil if no created_at" do
        record[:created_at] = nil
        expect(record.age_in_days).to be_nil
      end
    end
    
    describe "#new?" do
      it "returns true for recently created records" do
        record[:created_at] = (fixed_now - 3 * 24 * 60 * 60).iso8601
        expect(record.new?(7)).to be true
      end
      
      it "returns false for old records" do
        record[:created_at] = (fixed_now - 10 * 24 * 60 * 60).iso8601
        expect(record.new?(7)).to be false
      end
      
      it "defaults to 7 days" do
        record[:created_at] = (fixed_now - 5 * 24 * 60 * 60).iso8601
        expect(record.new?).to be true
      end
    end
    
    describe "#old?" do
      it "returns true for old records" do
        record[:created_at] = (fixed_now - 400 * 24 * 60 * 60).iso8601
        expect(record.old?(365)).to be true
      end
      
      it "returns false for newer records" do
        record[:created_at] = (fixed_now - 100 * 24 * 60 * 60).iso8601
        expect(record.old?(365)).to be false
      end
      
      it "defaults to 365 days" do
        record[:created_at] = (fixed_now - 400 * 24 * 60 * 60).iso8601
        expect(record.old?).to be true
      end
    end
  end
end