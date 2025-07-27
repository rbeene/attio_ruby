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
  config.api_key = token.access_token  # Access token from the exchange_code_for_token response
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
      target_record: "rec_789def012"  # Replace with actual person record ID
    }]
  }
)
```

#### Retrieving Records

```ruby
# Get a specific record
person = Attio::Record.retrieve(
  object: "people",
  record_id: "rec_456def789"  # Replace with actual record ID
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
  record_id: "rec_456def789",  # Replace with actual record ID
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
page = people
while page.has_more?
  page.each do |person|
    puts person[:name]
  end
  page = page.next_page
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
Attio::Record.delete(object: "people", record_id: "rec_123abc456")  # Replace with actual record ID
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
entry = list.add_record("rec_789def012")  # Replace with actual record ID

# List entries
entries = list.entries
entries.each do |entry|
  puts entry.record_id
end

# Remove from list (requires entry_id, not record_id)
list.remove_record("ent_456ghi789")  # Replace with actual list entry ID

# Delete list
list.destroy
```

### Notes

Add notes to records to track interactions and important information.

```ruby
# Create a note
note = Attio::Note.create(
  parent_object: "people",
  parent_record_id: "rec_123abc456",  # Replace with actual record ID
  content: "Had a great meeting about the new project.",
  format: "plaintext" # or "markdown"
)

# List notes for a record
notes = Attio::Note.list(
  parent_object: "people",
  parent_record_id: "rec_123abc456"  # Replace with actual record ID
)

# Notes are immutable - create a new note instead of updating
# To "update" a note, you would delete the old one and create a new one

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
webhook[:active] = false
webhook.save

# Delete webhook
webhook.destroy

# Verify webhook signatures
Attio::Util::WebhookSignature.verify!(
  payload: request.body.read,
  signature: request.headers['Attio-Signature'],
  secret: ENV['WEBHOOK_SECRET']
)
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
new_token = oauth.refresh_token("rtok_xyz789ghi012")  # Replace with actual refresh token

# Token introspection
info = oauth.introspect_token("tok_abc123def456")  # Replace with actual access token
puts info[:active] # => true

# Token revocation
oauth.revoke_token("tok_abc123def456")  # Replace with actual access token
```


### Error Handling

The gem provides comprehensive error handling:

```ruby
begin
  person = Attio::Record.create(
    object: "people",
    values: { email_addresses: "invalid-email" }
  )
rescue Attio::InvalidRequestError => e
  puts "Validation error: #{e.message}"
  puts "HTTP status: #{e.code}"
  puts "Request ID: #{e.request_id}"
rescue Attio::AuthenticationError => e
  puts "Auth failed: #{e.message}"
  puts "Request ID: #{e.request_id}"
rescue Attio::RateLimitError => e
  puts "Rate limited: #{e.message}"
rescue Attio::ConnectionError => e
  puts "Network error: #{e.message}"
rescue Attio::Error => e
  puts "API error: #{e.message}"
  puts "HTTP status: #{e.code}"
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