# Attio Ruby SDK

[![Gem Version](https://badge.fury.io/rb/attio-ruby.svg)](https://badge.fury.io/rb/attio-ruby)
[![Build Status](https://github.com/rbeene/attio_ruby/workflows/CI/badge.svg)](https://github.com/rbeene/attio_ruby/actions)
[![Documentation](https://img.shields.io/badge/docs-YARD-blue.svg)](https://rubydoc.info/gems/attio-ruby)

> **Note**: This gem is pending publication to RubyGems.org. Documentation links will become active once the gem is published.

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
person = Attio::Person.create(
  first_name: "John",
  last_name: "Doe",
  email: "john@example.com"
)

# Search for companies
companies = Attio::Company.list(
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
person = Attio::Person.create(
  first_name: "Jane",
  last_name: "Doe",
  api_key: "different_api_key"
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

For user-facing applications, use OAuth 2.0. The gem includes OAuth support, but for a complete OAuth integration example, see our companion Rails application (coming soon).

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

Records are instances of objects (e.g., individual people or companies). The gem provides typed classes (`Attio::Person`, `Attio::Company`) that inherit from `TypedRecord`, offering a cleaner interface than the generic `Attio::Record` class.

#### Complex Attributes

The gem provides convenient methods for working with complex attributes. You can use the simplified interface or the raw API format:

**Simple Interface (Recommended):**
```ruby
# The gem handles the complex structure for you
person = Attio::Person.create(
  first_name: "John",
  last_name: "Smith",
  email: "john@example.com",
  phone: "+15558675309",
  job_title: "Developer"
)

company = Attio::Company.create(
  name: "Acme Corp",
  domain: "acme.com",
  employee_count: "50-100"
)
```

**Raw API Format (Advanced):**
If you need full control, you can use the raw API structures:

```ruby
# Names
values: {
  name: [{
    first_name: "John",
    last_name: "Smith",
    full_name: "John Smith"
  }]
}

# Phone Numbers
values: {
  phone_numbers: [{
    original_phone_number: "+15558675309",
    country_code: "US"
  }]
}

# Addresses
values: {
  primary_location: [{
    line_1: "1 Infinite Loop",
    locality: "Cupertino",
    region: "CA",
    postcode: "95014",
    country_code: "US"
  }]
}

# Email addresses and domains (simple arrays)
values: {
  email_addresses: ["john@example.com", "john.smith@company.com"],
  domains: ["example.com", "example.org"]
}
```

#### Creating Records

```ruby
# Create a person
person = Attio::Person.create(
  first_name: "Jane",
  last_name: "Smith",
  email: "jane@example.com",
  phone: "+1-555-0123",
  job_title: "CEO"
)

# Create a company
company = Attio::Company.create(
  name: "Acme Corp",
  domain: "acme.com",
  values: {
    industry: "Technology"
  }
)
```

#### Retrieving Records

```ruby
# Get a specific person
person = Attio::Person.retrieve("rec_456def789")

# Access attributes using bracket notation
puts person[:name]
puts person[:email_addresses]
puts person[:job_title]

# Note: Attributes can be accessed with bracket notation and symbols
```

#### Updating Records

```ruby
# Update a record using attribute setters
person[:job_title] = "CTO"
person[:tags] = ["vip", "customer"]
person.save

# Or update directly
Attio::Person.update(
  "rec_456def789",
  values: { job_title: "CTO" }
)
```

#### Searching and Filtering

```ruby
# Simple search
people = Attio::Person.search("john")

# Advanced filtering
executives = Attio::Person.list(
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
Attio::Person.delete("rec_123abc456")  # Replace with actual record ID
```

#### Note on Batch Operations

The Attio API does not currently support batch operations for creating, updating, or deleting multiple records in a single request. Each record must be processed individually. If you need to process many records, consider implementing rate limiting and error handling in your application.

### Convenience Methods

The gem provides many convenience methods to make working with records easier:

#### Person Methods

```ruby
person = Attio::Person.retrieve("rec_123")

# Access methods
person.email          # Returns primary email address
person.phone          # Returns primary phone number  
person.first_name     # Returns first name
person.last_name      # Returns last name
person.full_name      # Returns full name

# Modification methods
person.set_name(first: "Jane", last: "Doe")
person.add_email("jane.doe@example.com")
person.add_phone("+14155551234", country_code: "US")

# Search methods
jane = Attio::Person.find_by_email("jane@example.com")
john = Attio::Person.find_by_name("John Smith")
```

#### Company Methods

```ruby
company = Attio::Company.retrieve("rec_456")

# Access methods
company.name          # Returns company name
company.domain        # Returns primary domain
company.domains_list  # Returns all domains

# Modification methods
company.name = "New Company Name"
company.add_domain("newdomain.com")
company.add_team_member(person)  # Associate a person with the company

# Search methods
acme = Attio::Company.find_by_name("Acme Corp")
tech_co = Attio::Company.find_by_domain("techcompany.com")
large_cos = Attio::Company.find_by_size(min: 100)
```

#### TypedRecord Methods

All typed records (Person, Company, and custom objects) support:

```ruby
# Search with query string
results = Attio::Person.search("john")

# Find by any attribute
person = Attio::Person.find_by(:job_title, "CEO")

# Aliases for common methods
Attio::Person.all == Attio::Person.list
Attio::Person.find("rec_123") == Attio::Person.retrieve("rec_123")
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
  person = Attio::Person.create(
    email: "invalid-email"
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
- `webhook_server.rb` - Webhook handling with signature verification

Run an example:

```bash
$ ruby examples/basic_usage.rb
```

## Testing

The gem includes comprehensive test coverage:

```bash
# Run all tests (unit tests only by default)
$ bundle exec rspec

# Run unit tests only
$ bundle exec rspec spec/unit

# Run integration tests (requires API key)
$ RUN_INTEGRATION_TESTS=true bundle exec rspec spec/integration
```

### Integration Tests

**Note**: This gem is under active development. To ensure our implementation matches the Attio API, we leverage live integration tests against a sandbox environment. This strategy will be removed once we hit a stable 1.0 release.

Integration tests make real API calls to Attio and are disabled by default. They serve to:

- Validate that our WebMock stubs match actual API behavior
- Test OAuth flows and complex scenarios
- Ensure the gem works correctly with the latest Attio API

To run integration tests:

1. Set up your environment variables:
   ```bash
   export ATTIO_API_KEY="your_api_key"
   export RUN_INTEGRATION_TESTS=true
   ```

2. Run the tests:
   ```bash
   bundle exec rspec spec/integration
   ```

**Warning**: Integration tests will create and delete real data in your Attio workspace. They include automatic cleanup, but use a test workspace if possible.

### Unit Tests

Unit tests use WebMock to stub all HTTP requests and do not require an API key. They run by default and ensure the gem's internal logic works correctly.

```bash
# Run only unit tests
bundle exec rspec spec/unit

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