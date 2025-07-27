# Attio Ruby SDK

[![Gem Version](https://badge.fury.io/rb/attio-ruby.svg)](https://badge.fury.io/rb/attio-ruby)
[![Build Status](https://github.com/rbeene/attio_ruby/workflows/CI/badge.svg)](https://github.com/rbeene/attio_ruby/actions)
[![Documentation](https://img.shields.io/badge/docs-YARD-blue.svg)](https://rubydoc.info/gems/attio-ruby)

A Ruby SDK for the [Attio API](https://attio.com/docs). This gem provides a simple and intuitive interface for interacting with Attio's CRM platform.

## Table of Contents

- [Installation](#installation)
- [Quick Start](#quick-start)
- [Configuration](#configuration)
- [Authentication](#authentication)
- [Basic Usage](#basic-usage)
  - [Working with Objects](#working-with-objects)
  - [Managing Records](#managing-records)
  - [Lists and List Entries](#lists-and-list-entries)
  - [Notes](#notes)
  - [Webhooks](#webhooks)
- [Advanced Features](#advanced-features)
  - [OAuth 2.0](#oauth-20)
  - [Service Classes](#service-classes)
  - [Batch Operations](#batch-operations)
  - [Caching](#caching)
  - [Error Handling](#error-handling)
- [Examples](#examples)
- [Testing](#testing)
- [Performance](#performance)
- [Contributing](#contributing)
- [License](#license)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'attio-ruby'
```

And then execute:

```bash
$ bundle install
```

Or install it yourself as:

```bash
$ gem install attio-ruby
```

## Quick Start

```ruby
require 'attio'

# Configure the client
Attio.configure do |config|
  config.api_key = ENV['ATTIO_API_KEY']
end

# Create a person
person = Attio::Record.create(
  object: "people",
  values: {
    name: "John Doe",
    email_addresses: "john@example.com"
  }
)

# Search for companies
companies = Attio::Record.list(
  object: "companies",
  params: { q: "tech", limit: 10 }
)
```

## Configuration

The gem can be configured globally or on a per-request basis:

### Global Configuration

```ruby
Attio.configure do |config|
  # Required
  config.api_key = "your_api_key"
  
  # Optional
  config.api_base = "https://api.attio.com" # Default
  config.api_version = "v2" # Default
  config.timeout = 30 # Request timeout in seconds
  config.max_retries = 3 # Number of retries for failed requests
  config.debug = false # Enable debug logging
  config.logger = Logger.new(STDOUT) # Custom logger
end
```

### Environment Variables

The gem automatically reads configuration from environment variables:

- `ATTIO_API_KEY` - Your API key
- `ATTIO_API_BASE` - API base URL (optional)
- `ATTIO_DEBUG` - Enable debug mode (optional)

### Per-Request Configuration

```ruby
# Override configuration for a single request
person = Attio::Record.create(
  object: "people",
  values: { name: "Jane Doe" },
  opts: { api_key: "different_api_key" }
)
```

## Authentication

### API Key Authentication

The simplest way to authenticate is using an API key:

```ruby
Attio.configure do |config|
  config.api_key = "your_api_key"
end
```

### OAuth 2.0 Authentication

For user-facing applications, use OAuth 2.0:

```ruby
# Initialize OAuth client
oauth_client = Attio::OAuth::Client.new(
  client_id: ENV['ATTIO_CLIENT_ID'],
  client_secret: ENV['ATTIO_CLIENT_SECRET'],
  redirect_uri: "https://yourapp.com/callback"
)

# Generate authorization URL
auth_data = oauth_client.authorization_url(
  scopes: %w[record:read record:write],
  state: "random_state"
)
redirect_to auth_data[:url]

# Exchange code for token
token = oauth_client.exchange_code_for_token(code: params[:code])

# Use the token
Attio.configure do |config|
  config.api_key = token.access_token
end
```

## Basic Usage

### Working with Objects

Objects represent the different types of records in your workspace (e.g., People, Companies).

```ruby
# List all objects
objects = Attio::Object.list
objects.each do |object|
  puts "#{object.plural_noun} (#{object.api_slug})"
end

# Get a specific object
people_object = Attio::Object.retrieve("people")
puts people_object.name # => "People"
```

### Managing Records

Records are instances of objects (e.g., individual people or companies).

#### Creating Records

```ruby
# Create a person
person = Attio::Record.create(
  object: "people",
  values: {
    name: "Jane Smith",
    email_addresses: "jane@example.com",
    phone_numbers: "+1-555-0123",
    job_title: "CEO"
  }
)

# Create a company with a relationship
company = Attio::Record.create(
  object: "companies",
  values: {
    name: "Acme Corp",
    domains: "acme.com",
    industry: "Technology",
    employees: [{ 
      target_object: "people", 
      target_record: person.id 
    }]
  }
)
```

#### Retrieving Records

```ruby
# Get a specific record
person = Attio::Record.retrieve(
  object: "people",
  record_id: "person_id"
)

# Access attributes
puts person[:name]
puts person[:email_addresses]
```

#### Updating Records

```ruby
# Update a record
person[:job_title] = "CTO"
person[:tags] = ["vip", "customer"]
person.save

# Or update directly
Attio::Record.update(
  object: "people",
  record_id: person.id,
  values: { job_title: "CTO" }
)
```

#### Searching and Filtering

```ruby
# Simple search
people = Attio::Record.list(
  object: "people",
  params: { q: "john" }
)

# Advanced filtering
executives = Attio::Record.list(
  object: "people",
  params: {
    filter: {
      job_title: { "$contains": "CEO" }
    },
    sort: [{ attribute: "name", direction: "asc" }],
    limit: 20
  }
)

# Pagination
people.each_page do |page|
  page.each do |person|
    puts person[:name]
  end
end

# Auto-pagination
people.auto_paging_each do |person|
  puts person[:name]
end
```

#### Deleting Records

```ruby
# Delete a record
person.destroy

# Or delete by ID
Attio::Record.delete(object: "people", record_id: "person_id")
```

### Lists and List Entries

Lists allow you to organize records into groups.

```ruby
# Create a list
list = Attio::List.create(
  name: "VIP Customers",
  object: "people"
)

# Add records to a list
entry = list.add_record("person_id")

# List entries
entries = list.entries
entries.each do |entry|
  puts entry.record_id
end

# Remove from list (requires entry_id, not record_id)
list.remove_record("entry_id")

# Delete list
list.destroy
```

### Notes

Add notes to records to track interactions and important information.

```ruby
# Create a note
note = Attio::Note.create(
  parent_object: "people",
  parent_record_id: person.id,
  content: "Had a great meeting about the new project.",
  format: "plaintext" # or "markdown"
)

# List notes for a record
notes = Attio::Note.list(
  parent_object: "people",
  parent_record_id: person.id
)

# Update a note
note.content = "Updated meeting notes"
note.save

# Delete a note
note.destroy
```

### Webhooks

Set up webhooks to receive real-time updates about changes in your workspace.

```ruby
# Create a webhook
webhook = Attio::Webhook.create(
  name: "Customer Updates",
  url: "https://yourapp.com/webhooks/attio",
  subscriptions: %w[record.created record.updated]
)

# List webhooks
webhooks = Attio::Webhook.list

# Update webhook
webhook.active = false
webhook.save

# Delete webhook
webhook.destroy

# Verify webhook signatures
verifier = Attio::Webhook::SignatureVerifier.new(ENV['WEBHOOK_SECRET'])
if verifier.verify(request.body.read, request.headers['Attio-Signature'])
  # Process webhook
end
```

## Advanced Features

### OAuth 2.0

Complete OAuth 2.0 flow implementation:

```ruby
# Initialize client
oauth = Attio::OAuth::Client.new(
  client_id: ENV['CLIENT_ID'],
  client_secret: ENV['CLIENT_SECRET'],
  redirect_uri: "https://yourapp.com/callback"
)

# Authorization
auth_data = oauth.authorization_url(
  scopes: %w[record:read record:write user:read],
  state: SecureRandom.hex(16)
)

# Token exchange
token = oauth.exchange_code_for_token(
  code: params[:code],
  state: params[:state]
)

# Token refresh
new_token = oauth.refresh_token(token.refresh_token)

# Token introspection
info = oauth.introspect_token(token.access_token)
puts info[:active] # => true

# Token revocation
oauth.revoke_token(token.access_token)
```

### Service Classes

Service classes provide high-level business logic and common patterns.

#### PersonService

```ruby
service = Attio::Services::PersonService.new

# Find or create by email
person = service.find_or_create_by_email(
  "john@example.com",
  defaults: {
    name: "John Doe",
    job_title: "Engineer"
  }
)

# Search by various criteria
people = service.search_by_name("John")
people = service.search_by_company("company_id")
people = service.search_by_email_domain("example.com")

# Merge duplicate records
service.merge("primary_person_id", ["duplicate_id_1", "duplicate_id_2"])

# Bulk operations with transactions
service.transaction do
  service.create_many([
    { name: "Person 1", email_addresses: "p1@example.com" },
    { name: "Person 2", email_addresses: "p2@example.com" }
  ])
end
```

#### CompanyService

```ruby
service = Attio::Services::CompanyService.new

# Find or create by domain
company = service.find_or_create_by_domain(
  "acme.com",
  defaults: {
    name: "Acme Corp",
    industry: "Technology"
  }
)

# Enrich company data
enriched = service.enrich_from_domain("example.com")

# Find related people
employees = service.find_employees("company_id")
```

### Batch Operations

Efficiently process large amounts of data:

```ruby
batch = Attio::Services::BatchService.new(
  batch_size: 50,
  parallel: true,
  max_threads: 4,
  on_progress: ->(progress) {
    puts "Processed #{progress[:completed]}/#{progress[:total]}"
  },
  on_error: ->(error, item) {
    puts "Error: #{error.message}"
  }
)

# Batch create
results = batch.create_records(
  "people" => [
    { values: { name: "Person 1", email_addresses: "p1@example.com" } },
    { values: { name: "Person 2", email_addresses: "p2@example.com" } }
  ],
  "companies" => [
    { values: { name: "Company 1", domains: "c1.com" } }
  ]
)

puts "Created: #{results[:success].size}"
puts "Failed: #{results[:failed].size}"

# Batch update
batch.update_records(
  "people" => [
    { record_id: "id1", values: { job_title: "CEO" } },
    { record_id: "id2", values: { job_title: "CTO" } }
  ]
)

# Batch delete
batch.delete_records(
  "people" => ["id1", "id2", "id3"]
)

# Batch upsert
batch.upsert_records(
  "people" => [
    { 
      matching_attribute: "email_addresses",
      values: { 
        name: "John Doe", 
        email_addresses: "john@example.com" 
      }
    }
  ]
)
```

### Caching

Improve performance with built-in caching:

```ruby
# Memory cache (default)
cache = Attio::Util::Cache::Memory.new(ttl: 300) # 5 minutes

# Redis cache
require 'redis'
cache = Attio::Util::Cache::Redis.new(
  client: Redis.new,
  ttl: 3600, # 1 hour
  namespace: "attio"
)

# Use with service classes
service = Attio::Services::PersonService.new(cache: cache)

# First call hits API
person = service.find_by_email("john@example.com")

# Subsequent calls use cache
person = service.find_by_email("john@example.com") # From cache
```

### Error Handling

The gem provides comprehensive error handling:

```ruby
begin
  person = Attio::Record.create(
    object: "people",
    values: { email_addresses: "invalid-email" }
  )
rescue Attio::Errors::InvalidRequestError => e
  puts "Validation error: #{e.message}"
  puts "Field errors: #{e.json_body['errors']}"
rescue Attio::Errors::AuthenticationError => e
  puts "Auth failed: #{e.message}"
  puts "Request ID: #{e.request_id}"
rescue Attio::Errors::RateLimitError => e
  puts "Rate limited. Retry after: #{e.retry_after}"
rescue Attio::Errors::ConnectionError => e
  puts "Network error: #{e.message}"
rescue Attio::Errors::APIError => e
  puts "API error: #{e.message}"
  puts "HTTP status: #{e.http_status}"
  puts "Request ID: #{e.request_id}"
end
```

## Examples

Complete example applications are available in the `examples/` directory:

- `basic_usage.rb` - Demonstrates core functionality
- `oauth_flow.rb` - Complete OAuth 2.0 implementation with Sinatra
- `batch_operations.rb` - Bulk data processing examples
- `webhook_server.rb` - Webhook handling with signature verification

Run an example:

```bash
$ ruby examples/basic_usage.rb
```

## Testing

The gem includes comprehensive test coverage:

```bash
# Run all tests
$ bundle exec rspec

# Run unit tests only
$ bundle exec rspec spec/unit

# Run integration tests (requires API key)
$ ATTIO_API_KEY=your_key RUN_INTEGRATION_TESTS=true bundle exec rspec spec/integration

# Run with coverage
$ COVERAGE=true bundle exec rspec
```

## Performance

The gem is optimized for performance:

- Connection pooling for HTTP keep-alive
- Automatic retry with exponential backoff
- Efficient pagination with auto-paging
- Batch operations for bulk processing
- Optional caching layer
- Thread-safe operations

Run benchmarks:

```bash
$ ruby benchmarks/api_performance.rb
$ ruby benchmarks/memory_profile.rb
```

## Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

The gem is available as open source under the terms of the [MIT License](LICENSE).