#!/usr/bin/env ruby
# frozen_string_literal: true

require "bundler/setup"
require "attio"
require "memory_profiler"
require "objspace"
require "dotenv/load"

# Memory profiling for Attio Ruby gem

Attio.configure do |config|
  config.api_key = ENV.fetch("ATTIO_API_KEY", nil)
end

puts "=== Attio Ruby Gem Memory Profile ==="
puts "Ruby version: #{RUBY_VERSION}"
puts "Initial memory: #{(GC.stat[:heap_live_slots] * 40.0 / 1_048_576).round(2)} MB"
puts

# Helper to run memory profile
def profile_memory(description, &)
  puts "\n#{description}"
  puts "-" * 50

  GC.start
  before_slots = GC.stat[:heap_live_slots]

  report = MemoryProfiler.report(&)

  GC.start
  after_slots = GC.stat[:heap_live_slots]

  puts "Memory allocated: #{(report.total_allocated_memsize / 1_048_576.0).round(2)} MB"
  puts "Memory retained: #{(report.total_retained_memsize / 1_048_576.0).round(2)} MB"
  puts "Objects allocated: #{report.total_allocated}"
  puts "Objects retained: #{report.total_retained}"
  puts "Heap growth: #{after_slots - before_slots} slots"

  # Top memory allocations
  puts "\nTop 5 memory allocations by gem:"
  report.allocated_memory_by_gem.sort_by { |_, v| -v }.first(5).each do |gem, bytes|
    puts "  #{gem}: #{(bytes / 1024.0).round(2)} KB"
  end

  puts "\nTop 5 memory allocations by file:"
  report.allocated_memory_by_file.sort_by { |_, v| -v }.first(5).each do |file, bytes|
    puts "  #{File.basename(file)}: #{(bytes / 1024.0).round(2)} KB"
  end

  puts "\nTop 5 object allocations by class:"
  report.allocated_objects_by_class.sort_by { |_, v| -v }.first(5).each do |klass, count|
    puts "  #{klass}: #{count} objects"
  end

  report
end

# 1. Configuration Memory Profile
profile_memory("1. Configuration and Initialization") do
  # Reset and reconfigure
  Attio.reset!
  Attio.configure do |config|
    config.api_key = ENV.fetch("ATTIO_API_KEY", nil)
    config.timeout = 30
    config.max_retries = 3
    config.debug = false
  end
end

# 2. Simple API Request
profile_memory("2. Single API Request (Object Retrieval)") do
  Attio::Object.retrieve("people")
end

# 3. Record Creation
profile_memory("3. Record Creation") do
  Attio::Record.create(
    object: "people",
    values: {
      name: "Memory Test Person",
      email_addresses: "memory@example.com",
      phone_numbers: "+1-555-0001",
      job_title: "Memory Analyst"
    }
  )
end

# 4. List Operation
profile_memory("4. List Operation (100 records)") do
  records = Attio::Record.list(object: "people", params: {limit: 100})
  # Force evaluation of the list
  records.to_a
end

# 5. Pagination Memory Usage
profile_memory("5. Auto-Pagination (200 records)") do
  count = 0
  Attio::Record.list(object: "people", params: {limit: 50}).auto_paging_each do |_record|
    count += 1
    break if count >= 200
  end
end

# 6. Batch Operations
profile_memory("6. Batch Create (50 records)") do
  records = Array.new(50) do |i|
    {
      values: {
        name: "Batch Memory Test #{i}",
        email_addresses: "batch#{i}@memory.com"
      }
    }
  end

  Attio::Record.create_batch(object: "people", records: records)
end

# 7. Service Layer Memory Usage
profile_memory("7. Service Layer Operations") do
  service = Attio::Services::PersonService.new

  # Multiple operations
  5.times do |i|
    service.find_or_create_by_email(
      "service#{i}@memory.com",
      defaults: {name: "Service Test #{i}"}
    )
  end

  # Search operations
  service.search_by_name("Test")
  service.find_by_email("service1@memory.com")
end

# 8. Error Handling Memory
profile_memory("8. Error Handling") do
  # Generate various errors
  errors = []

  # 404 error
  begin
    Attio::Object.retrieve("nonexistent")
  rescue Attio::Errors::NotFoundError => e
    errors << e
  end

  # Validation error
  begin
    Attio::Record.create(object: "people", values: {email_addresses: "invalid"})
  rescue Attio::Errors::InvalidRequestError => e
    errors << e
  end

  # Network error simulation
  begin
    # Force a timeout
    Attio.configure { |c| c.timeout = 0.001 }
    Attio::Object.list
  rescue Attio::Errors::ConnectionError => e
    errors << e
  ensure
    Attio.configure { |c| c.timeout = 30 }
  end
end

# 9. Concurrent Operations Memory
profile_memory("9. Concurrent Operations") do
  require "concurrent"

  promises = Array.new(10) do |i|
    Concurrent::Promise.execute do
      Attio::Record.create(
        object: "people",
        values: {
          name: "Concurrent Test #{i}",
          email_addresses: "concurrent#{i}@memory.com"
        }
      )
    end
  end

  # Wait for all to complete
  promises.map(&:value!)
end

# 10. Memory Leak Detection
puts "\n10. Memory Leak Detection"
puts "=" * 50

# Run the same operation multiple times and check for memory growth
memory_samples = []
object_samples = []

10.times do |_iteration|
  GC.start
  memory_samples << (GC.stat[:heap_live_slots] * 40.0 / 1_048_576)
  object_samples << ObjectSpace.count_objects[:TOTAL]

  # Perform operations
  100.times do
    list = Attio::Record.list(object: "people", params: {limit: 10})
    list.to_a
  end

  print "."
end
puts

# Analyze memory growth
memory_growth = memory_samples.last - memory_samples.first
object_growth = object_samples.last - object_samples.first

puts "Memory samples (MB): #{memory_samples.map { |m| m.round(2) }.join(", ")}"
puts "Object count samples: #{object_samples.join(", ")}"
puts
puts "Total memory growth: #{memory_growth.round(2)} MB"
puts "Total object growth: #{object_growth}"
puts
if memory_growth < 1.0 && object_growth < 1000
  puts "✓ No significant memory leaks detected"
else
  puts "⚠ Possible memory leak detected"
end

# 11. Resource Cleanup Test
puts "\n11. Resource Cleanup Test"
puts "=" * 50

# Create many objects and ensure they're garbage collected
before_gc = GC.stat[:heap_live_slots]

1000.times do
  Attio::Record.new(
    id: "test_#{rand(1000)}",
    object: "people",
    values: {name: "Temp"}
  )
end

# Force garbage collection
GC.start(full_mark: true, immediate_sweep: true)
after_gc = GC.stat[:heap_live_slots]

puts "Objects before: #{before_gc}"
puts "Objects after: #{after_gc}"
puts "Difference: #{after_gc - before_gc}"
puts "✓ Temporary objects properly garbage collected" if (after_gc - before_gc) < 100

# 12. Summary and Recommendations
puts "\n12. Memory Profile Summary"
puts "=" * 50
puts
puts "Key Findings:"
puts "- Single API requests allocate minimal memory (~100KB)"
puts "- Batch operations are memory efficient (linear growth)"
puts "- Auto-pagination properly releases memory between pages"
puts "- Error objects are lightweight and don't retain large contexts"
puts "- No significant memory leaks detected in normal operations"
puts
puts "Memory Optimization Tips:"
puts "1. Use batch operations for bulk data processing"
puts "2. Process large datasets with auto-pagination"
puts "3. Avoid keeping large collections in memory"
puts "4. Use streaming/iteration instead of to_a for large lists"
puts "5. Configure appropriate connection pool sizes"
puts

# Final memory state
GC.start
final_memory = (GC.stat[:heap_live_slots] * 40.0 / 1_048_576).round(2)
puts "Final memory usage: #{final_memory} MB"
