#!/usr/bin/env ruby
# frozen_string_literal: true

require "bundler/setup"
require "attio"

# Configure the client
Attio.configure do |config|
  config.api_key = ENV["ATTIO_API_KEY"]
end

puts "=== Typed Records Example ==="
puts

# Old way vs New way comparison
puts "OLD WAY - Using generic Record class:"
puts "-------------------------------------"
puts <<~OLD
  # Creating a person (verbose and error-prone)
  person = Attio::Record.create(
    object: "people",
    values: {
      name: [{
        first_name: "John",
        last_name: "Doe",
        full_name: "John Doe"
      }],
      email_addresses: ["john@example.com"],
      phone_numbers: [{
        original_phone_number: "+12125551234",
        country_code: "US"
      }]
    }
  )

  # Listing people
  people = Attio::Record.list(object: "people", params: { q: "john" })

  # Creating a company
  company = Attio::Record.create(
    object: "companies",
    values: {
      name: "Acme Corp",
      domains: ["acme.com"]
    }
  )
OLD

puts
puts "NEW WAY - Using typed Person and Company classes:"
puts "-------------------------------------------------"
puts <<~NEW
  # Creating a person (simple and intuitive)
  person = Attio::Person.create(
    first_name: "John",
    last_name: "Doe",
    email: "john@example.com",
    phone: "+12125551234",
    job_title: "Software Engineer"
  )

  # Or use the People alias
  person = Attio::People.create(
    first_name: "Jane",
    last_name: "Smith"
  )

  # Convenient name setters
  person.set_name(first: "Jane", last: "Johnson")
  
  # Easy access to attributes
  puts person.full_name  # => "Jane Johnson"
  puts person.email      # => "john@example.com"
  puts person.phone      # => "+12125551234"

  # Searching is simpler
  people = Attio::Person.search("john")
  people = Attio::Person.find_by_email("john@example.com")
  people = Attio::Person.find_by_name("John Doe")

  # Creating a company (no more array wrapping for simple names!)
  company = Attio::Company.create(
    name: "Acme Corp",
    domain: "acme.com",
    description: "Leading widget manufacturer",
    employee_count: "50-100"
  )

  # Or use the Companies alias
  company = Attio::Companies.create(
    name: "Tech Startup",
    domains: ["techstartup.com", "techstartup.io"]
  )

  # Simple attribute access
  company.name = "Acme Corporation"
  company.add_domain("acme.org")
  
  # Associate person with company
  person.company = company
  person.save

  # Find company's team members
  team = company.team_members

  # Find companies by various criteria
  company = Attio::Company.find_by_domain("acme.com")
  company = Attio::Company.find_by_name("Acme")
  large_companies = Attio::Company.find_by_size(100)  # 100+ employees
NEW

# Working example (if API key is set)
puts
if ENV["ATTIO_API_KEY"]
  puts "Running live examples..."
  puts

  begin
    # Create a person the new way
    person = Attio::Person.create(
      first_name: "Test",
      last_name: "User-#{Time.now.to_i}",
      email: "test#{Time.now.to_i}@example.com",
      job_title: "Developer"
    )

    puts "Created person:"
    puts "  ID: #{person.id["record_id"]}"
    puts "  Name: #{person.full_name}"
    puts "  Email: #{person.email}"
    puts "  Job: #{person[:job_title]}"

    # Create a company the new way
    company = Attio::Company.create(
      name: "Test Company #{Time.now.to_i}",
      domain: "test#{Time.now.to_i}.com"
    )

    puts
    puts "Created company:"
    puts "  ID: #{company.id["record_id"]}"
    puts "  Name: #{company.name}"
    puts "  Domain: #{company.domain}"

    # Update person's name using helper
    person.set_name(first: "Updated", last: "Name")
    person.save

    puts
    puts "Updated person name: #{person.full_name}"

    # Search for people
    results = Attio::Person.search("test")
    puts
    puts "Found #{results.count} people matching 'test'"

    # Clean up
    person.destroy
    company.destroy
    puts
    puts "Cleaned up test data"
  rescue Attio::Error => e
    puts "Error: #{e.message}"
  end
else
  puts "To run live examples, set ATTIO_API_KEY environment variable"
end
