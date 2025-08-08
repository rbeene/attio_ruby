#!/usr/bin/env ruby
# frozen_string_literal: true

require "bundler/setup"
require "attio"

# This example demonstrates working with Deals in Attio

# Setup
Attio.api_key = ENV["ATTIO_API_KEY"] || raise("Please set ATTIO_API_KEY")
owner_email = ENV["ATTIO_TEST_USER_EMAIL"] || "sales@example.com"

puts "=== Creating Deals ==="

# Create a basic deal
deal = Attio::Deal.create(
  name: "Enterprise Software Deal",
  value: 50000,
  stage: "In Progress",
  owner: owner_email
)

puts "Created deal: #{deal.name}"
puts "Value: $#{deal.value["currency_value"]}"
puts "Stage: #{deal.stage["status"]["title"]}"

# Create a deal with associations
partnership_deal = Attio::Deal.create(
  name: "Partnership Deal",
  value: 100000,
  stage: "Lead",
  owner: owner_email,
  associated_people: ["partner@example.com", "contact@partner.com"],
  associated_company: ["partner.com"]
)

puts "\nCreated partnership deal with associations"

puts "\n=== Searching Deals ==="

# Find high-value deals
big_deals = Attio::Deal.find_by_value_range(min: 75000)
puts "Found #{big_deals.count} deals worth $75k+"

# Find deals in a value range
mid_deals = Attio::Deal.find_by_value_range(min: 25000, max: 75000)
puts "Found #{mid_deals.count} deals worth $25k-$75k"

# Find deals by stage
in_progress = Attio::Deal.find_by(stage: "In Progress")
puts "Found #{in_progress ? 1 : 0} deals in progress"

puts "\n=== Updating Deals ==="

# Update deal stage
deal.update_stage("Won 🎉")
puts "Updated deal stage to: Won 🎉"

# Update deal value
deal.update_value(75000)
puts "Updated deal value to: $75,000"

# Check deal status
puts "\nDeal status checks:"
puts "Is open? #{deal.open?}"
puts "Is won? #{deal.won?}"
puts "Is lost? #{deal.lost?}"

puts "\n=== Deal Pipeline Analysis ==="

# List all deals and analyze by stage
all_deals = Attio::Deal.list(params: {limit: 50})
stage_counts = Hash.new(0)

all_deals.each do |d|
  stage_title = d.stage.dig("status", "title") if d.stage.is_a?(Hash)
  stage_counts[stage_title || "Unknown"] += 1
end

puts "Pipeline breakdown:"
stage_counts.each do |stage, count|
  puts "  #{stage}: #{count} deals"
end

# Calculate total pipeline value
total_value = all_deals.sum do |d|
  d.value.is_a?(Hash) ? (d.value["currency_value"] || 0) : 0
end

puts "\nTotal pipeline value: $#{total_value}"

puts "\n=== Working with Deal Relationships ==="

# Get associated company (if available)
if deal.company
  begin
    company = deal.company_record
    puts "Deal is associated with: #{company.name}" if company
  rescue => e
    puts "Could not fetch company: #{e.message}"
  end
end

puts "\n=== Cleanup ==="

# Clean up test deals
[deal, partnership_deal].each do |d|
  d.destroy if d.persisted?
  puts "Deleted deal: #{d.name}"
end

puts "\nDone!"
