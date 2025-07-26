#!/usr/bin/env ruby
# frozen_string_literal: true

require "bundler/setup"
require "attio"
require "dotenv/load"

# Basic usage example for Attio Ruby gem

# Configure the client
Attio.configure do |config|
  config.api_key = ENV.fetch("ATTIO_API_KEY", nil)
  # Optional configurations
  # config.api_base = "https://api.attio.com"
  # config.timeout = 30
  # config.debug = true
end

puts "=== Attio Ruby Gem Basic Usage Example ==="
puts

# 1. Working with Objects
puts "1. Listing Objects:"
objects = Attio::Object.list
objects.each do |object|
  puts "  - #{object.plural_noun} (#{object.api_slug})"
end
puts

# 2. Working with Records (People)
puts "2. Creating a Person:"
person = Attio::Record.create(
  values: {
    name: "John Doe",
    email_addresses: "john@example.com",
    phone_numbers: "+1-555-0123",
    job_title: "Software Engineer"
  },
  object: "people"
)
puts "  Created: #{person[:name]} (ID: #{person.id})"
puts

# 3. Searching for Records
puts "3. Searching for People:"
people = Attio::Record.list(
  {
    q: "john",
    limit: 5
  },
  object: "people"
)
puts "  Found #{people.count} people matching 'john'"
people.each do |p|
  puts "  - #{p[:name]} (#{p[:email_addresses]})"
end
puts

# 4. Working with Companies
puts "4. Creating a Company:"
company = Attio::Record.create(
  values: {
    name: "Acme Corporation",
    domains: "acme.com",
    industry: "Technology",
    company_size: "50-100"
  },
  object: "companies"
)
puts "  Created: #{company[:name]} (ID: #{company.id})"
puts

# 5. Updating Records
puts "5. Updating a Record:"
person[:job_title] = "Senior Software Engineer"
person[:company] = [{target_object: "companies", target_record: company.id}]
person.save
puts "  Updated #{person[:name]}'s job title and company"
puts

# 6. Working with Lists
puts "6. Creating and Managing Lists:"
list = Attio::List.create(
  name: "VIP Customers",
  object: "people"
)
puts "  Created list: #{list.name}"

# Add person to list
list.add_record(person.id)
puts "  Added #{person[:name]} to #{list.name}"
puts

# 7. Adding Notes
puts "7. Adding a Note:"
Attio::Note.create(
  parent_object: "people",
  parent_record_id: person.id,
  content: "Had a great meeting about the new project. Very interested in our solution.",
  format: "plaintext"
)
puts "  Added note to #{person[:name]}'s record"
puts

# 8. Working with Attributes
puts "8. Listing Attributes for People:"
attributes = Attio::Attribute.list(object: "people")
puts "  People object has #{attributes.count} attributes:"
attributes.first(5).each do |attr|
  puts "  - #{attr.name} (#{attr.type})"
end
puts

# 9. Using Service Classes
puts "9. Using Service Classes:"
person_service = Attio::Services::PersonService.new

# Find or create by email
existing_person = person_service.find_or_create_by_email(
  "jane@example.com",
  defaults: {
    name: "Jane Smith",
    job_title: "Product Manager"
  }
)
puts "  Found or created: #{existing_person[:name]}"

# Search by name
results = person_service.search_by_name("Jane")
puts "  Found #{results.count} people named Jane"
puts

# 10. Batch Operations
puts "10. Batch Operations:"
batch_service = Attio::Services::BatchService.new(
  on_progress: ->(_progress) { print "." }
)

puts "  Creating multiple records in batch..."
batch_results = batch_service.create_records(
  "people" => [
    {values: {name: "Alice Johnson", email_addresses: "alice@example.com"}},
    {values: {name: "Bob Wilson", email_addresses: "bob@example.com"}}
  ]
)
puts "\n  Created #{batch_results[:success].size} records successfully"
puts

# 11. Error Handling
puts "11. Error Handling Example:"
begin
  # Try to create a record without required fields
  Attio::Record.create(object: "invalid_object", values: {})
rescue Attio::Errors::NotFoundError => e
  puts "  Caught error: #{e.message}"
  puts "  Request ID: #{e.request_id}" if e.request_id
end
puts

puts "=== Example Complete ==="
puts "This example demonstrated:"
puts "- Configuring the client"
puts "- Creating and updating records"
puts "- Searching and filtering"
puts "- Working with lists and notes"
puts "- Using service classes"
puts "- Batch operations"
puts "- Error handling"
