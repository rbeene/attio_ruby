#!/usr/bin/env ruby
# frozen_string_literal: true

require "bundler/setup"
require "attio"
require "dotenv/load"
require "csv"
require "json"

# Batch operations example for Attio Ruby gem
# Demonstrates efficient bulk data operations

Attio.configure do |config|
  config.api_key = ENV.fetch("ATTIO_API_KEY", nil)
  config.debug = true if ENV["DEBUG"]
end

puts "=== Attio Ruby Gem Batch Operations Example ==="
puts

# 1. Batch Create Records
puts "1. Batch Creating Records:"
batch_service = Attio::Services::BatchService.new(
  batch_size: 50,
  on_progress: lambda { |progress|
    print "\r  Progress: #{progress[:completed]}/#{progress[:total]} " \
          "(#{(progress[:completed].to_f / progress[:total] * 100).round(1)}%)"
  }
)

# Prepare sample data
people_data = 10.times.map do |i|
  {
    values: {
      name: "Test Person #{i + 1}",
      email_addresses: "test#{i + 1}@example.com",
      phone_numbers: "+1-555-#{format('%04d', i + 1)}",
      job_title: %w[Engineer Manager Designer Analyst].sample
    }
  }
end

companies_data = 5.times.map do |i|
  {
    values: {
      name: "Test Company #{i + 1}",
      domains: "company#{i + 1}.com",
      industry: %w[Technology Finance Healthcare Retail].sample,
      company_size: %w[1-10 11-50 51-200 201-500].sample
    }
  }
end

# Create records in batch
results = batch_service.create_records(
  "people" => people_data,
  "companies" => companies_data
)
puts
puts "  Created #{results[:success].size} records successfully"
puts "  Failed: #{results[:failed].size}"
puts

# 2. Batch Update Records
puts "2. Batch Updating Records:"

# Get some records to update
people = Attio::Record.list(object: "people", params: { limit: 5 })
update_data = people.map do |person|
  {
    record_id: person.id,
    values: {
      job_title: "Senior #{person[:job_title] || 'Professional'}",
      tags: %w[batch-updated example]
    }
  }
end

update_results = batch_service.update_records(
  "people" => update_data
)
puts "  Updated #{update_results[:success].size} records"
puts

# 3. Batch Operations with CSV
puts "3. Batch Import from CSV:"

# Create sample CSV data
csv_data = CSV.generate do |csv|
  csv << %w[name email company job_title phone]
  csv << ["Alice Cooper", "alice@rockband.com", "Rock Industries", "Lead Singer", "+1-555-1111"]
  csv << ["Bob Dylan", "bob@folk.com", "Folk Music Co", "Songwriter", "+1-555-2222"]
  csv << ["Charlie Parker", "charlie@jazz.com", "Jazz Enterprises", "Saxophonist", "+1-555-3333"]
end

# Parse and import CSV
csv_records = []
CSV.parse(csv_data, headers: true) do |row|
  csv_records << {
    values: {
      name: row["name"],
      email_addresses: row["email"],
      job_title: row["job_title"],
      phone_numbers: row["phone"]
    }
  }
end

csv_results = batch_service.create_records("people" => csv_records)
puts "  Imported #{csv_results[:success].size} records from CSV"
puts

# 4. Batch Delete with Filtering
puts "4. Batch Delete Operations:"

# Find records with specific tag
tagged_people = Attio::Record.list(
  object: "people",
  params: {
    q: "tag:batch-updated",
    limit: 100
  }
)

if tagged_people.any?
  delete_results = batch_service.delete_records(
    "people" => tagged_people.map(&:id)
  )
  puts "  Deleted #{delete_results[:success].size} records"
else
  puts "  No records to delete"
end
puts

# 5. Batch Operations with Error Handling
puts "5. Batch Operations with Error Handling:"

# Intentionally include some invalid data
mixed_data = [
  { values: { name: "Valid Person", email_addresses: "valid@example.com" } },
  { values: { name: "" } }, # Invalid: empty name
  { values: { name: "Another Valid", email_addresses: "another@example.com" } },
  { values: { email_addresses: "no-name@example.com" } } # Missing required field
]

batch_service_with_errors = Attio::Services::BatchService.new(
  on_progress: ->(_p) { print "." },
  on_error: lambda { |error, item|
    puts "\n  Error: #{error.message} for item: #{item[:values]}"
  }
)

error_results = batch_service_with_errors.create_records("people" => mixed_data)
puts
puts "  Success: #{error_results[:success].size}"
puts "  Failed: #{error_results[:failed].size}"
error_results[:failed].each do |failure|
  puts "    - #{failure[:error]}: #{failure[:item][:values]}"
end
puts

# 6. Batch Export to JSON
puts "6. Batch Export to JSON:"

# Export all people created in this session
all_people = Attio::Record.list(
  object: "people",
  params: {
    q: "created_at:>1hour",
    limit: 1000
  }
)

export_data = {
  export_date: Time.now.iso8601,
  total_records: all_people.count,
  records: all_people.map do |person|
    {
      id: person.id,
      name: person[:name],
      email: person[:email_addresses],
      job_title: person[:job_title],
      created_at: person[:created_at]
    }
  end
}

File.write("attio_export_#{Time.now.strftime('%Y%m%d_%H%M%S')}.json", JSON.pretty_generate(export_data))
puts "  Exported #{all_people.count} records to JSON file"
puts

# 7. Batch Relationship Updates
puts "7. Batch Relationship Updates:"

# Get some people and companies
people_for_relationships = Attio::Record.list(object: "people", params: { limit: 3 })
companies = Attio::Record.list(object: "companies", params: { limit: 2 })

if people_for_relationships.any? && companies.any?
  relationship_updates = people_for_relationships.map do |person|
    {
      record_id: person.id,
      values: {
        company: [{
          target_object: "companies",
          target_record: companies.sample.id
        }]
      }
    }
  end

  rel_results = batch_service.update_records("people" => relationship_updates)
  puts "  Updated #{rel_results[:success].size} person-company relationships"
else
  puts "  Not enough records for relationship updates"
end
puts

# 8. Parallel Batch Operations
puts "8. Parallel Batch Operations:"

# Create batch service with parallelization
parallel_batch = Attio::Services::BatchService.new(
  batch_size: 25,
  parallel: true,
  max_threads: 4,
  on_progress: lambda { |p|
    puts "  Thread #{Thread.current.object_id}: Processed batch #{p[:batch]}"
  }
)

# Generate larger dataset
large_dataset = 100.times.map do |i|
  {
    values: {
      name: "Bulk Person #{i + 1}",
      email_addresses: "bulk#{i + 1}@example.com"
    }
  }
end

start_time = Time.now
parallel_results = parallel_batch.create_records("people" => large_dataset)
end_time = Time.now

puts "  Created #{parallel_results[:success].size} records in #{(end_time - start_time).round(2)}s"
puts "  Average: #{((end_time - start_time) / large_dataset.size * 1000).round(2)}ms per record"
puts

# 9. Batch Upsert Operations
puts "9. Batch Upsert (Find or Create):"

upsert_data = [
  {
    matching_attribute: "email_addresses",
    values: {
      name: "John Upsert",
      email_addresses: "john.upsert@example.com",
      job_title: "Updated Title"
    }
  },
  {
    matching_attribute: "email_addresses",
    values: {
      name: "Jane Upsert",
      email_addresses: "jane.upsert@example.com",
      job_title: "New Title"
    }
  }
]

upsert_results = batch_service.upsert_records("people" => upsert_data)
puts "  Upserted #{upsert_results[:success].size} records"
puts "  Created: #{upsert_results[:created]}"
puts "  Updated: #{upsert_results[:updated]}"
puts

# 10. Batch Operations Summary Report
puts "10. Batch Operations Summary:"
puts "  This example demonstrated:"
puts "  - Batch creating multiple record types"
puts "  - Batch updating with progress tracking"
puts "  - CSV import/export operations"
puts "  - Error handling in batch operations"
puts "  - Parallel processing for performance"
puts "  - Upsert operations for deduplication"
puts "  - Relationship updates in bulk"
puts
puts "=== Example Complete ==="

# Cleanup (optional)
if ENV["CLEANUP"]
  puts "\nCleaning up test data..."
  cleanup_people = Attio::Record.list(
    object: "people",
    params: { q: "email:*@example.com", limit: 1000 }
  )

  if cleanup_people.any?
    cleanup_results = batch_service.delete_records(
      "people" => cleanup_people.map(&:id)
    )
    puts "Deleted #{cleanup_results[:success].size} test records"
  end
end
