# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Deal Required Fields Discovery", integration: true do
  let(:unique_id) { "#{Time.now.to_i}-#{rand(10000)}" }

  it "discovers required fields by trying different combinations" do
    puts "\n=== Testing Deal Creation with Different Field Combinations ==="
    
    # Test 1: Just name
    puts "\nTest 1: Creating with just name..."
    begin
      deal = Attio::Deal.create(name: "Test Deal #{unique_id}")
      puts "SUCCESS! Deal created with just name"
      deal.destroy
    rescue Attio::BadRequestError => e
      puts "FAILED: #{e.message}"
    end
    
    # Test 2: Name + Stage
    puts "\nTest 2: Creating with name + stage..."
    begin
      deal = Attio::Deal.create(
        name: "Test Deal #{unique_id}",
        stage: "Lead"
      )
      puts "SUCCESS! Deal created with name + stage"
      deal.destroy
    rescue Attio::BadRequestError => e
      puts "FAILED: #{e.message}"
    end
    
    # Test 3: Name + Value
    puts "\nTest 3: Creating with name + value..."
    begin
      deal = Attio::Deal.create(
        name: "Test Deal #{unique_id}",
        value: 10000
      )
      puts "SUCCESS! Deal created with name + value"
      deal.destroy
    rescue Attio::BadRequestError => e
      puts "FAILED: #{e.message}"
    end
    
    # Test 4: Name + Stage + Value
    puts "\nTest 4: Creating with name + stage + value..."
    begin
      deal = Attio::Deal.create(
        name: "Test Deal #{unique_id}",
        stage: "Lead",
        value: 10000
      )
      puts "SUCCESS! Deal created with name + stage + value"
      deal.destroy
    rescue Attio::BadRequestError => e
      puts "FAILED: #{e.message}"
    end
    
    # Test 5: All standard fields
    puts "\nTest 5: Creating with all standard fields..."
    begin
      deal = Attio::Deal.create(
        name: "Test Deal #{unique_id}",
        stage: "Lead",
        value: 10000,
        owner: "test@example.com"
      )
      puts "SUCCESS! Deal created with all standard fields"
      deal.destroy
    rescue Attio::BadRequestError => e
      puts "FAILED: #{e.message}"
    end
    
    # Test 6: Try different stage values
    puts "\nTest 6: Testing different stage values..."
    ["Lead", "In Progress", "Won 🎉", "Lost"].each do |stage_value|
      begin
        deal = Attio::Deal.create(
          name: "Test Deal #{unique_id} - #{stage_value}",
          stage: stage_value,
          value: 10000
        )
        puts "  SUCCESS with stage: #{stage_value}"
        deal.destroy
      rescue Attio::BadRequestError => e
        puts "  FAILED with stage '#{stage_value}': #{e.message}"
      end
    end
  end
  
  it "tests value field formats" do
    puts "\n=== Testing Value Field Formats ==="
    
    # Test different value formats
    [1000, 1000.50, "1000", 0, -1000].each do |value_test|
      begin
        deal = Attio::Deal.create(
          name: "Value Test #{unique_id}",
          stage: "Lead", 
          value: value_test
        )
        puts "SUCCESS with value: #{value_test} (#{value_test.class})"
        deal.destroy
      rescue Attio::BadRequestError => e
        puts "FAILED with value #{value_test}: #{e.message}"
      end
    end
  end
end