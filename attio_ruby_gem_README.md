# Attio Ruby Client Library

A professional Ruby gem for interacting with the Attio API - a flexible data modeling and management platform for modern businesses.

## Table of Contents

- [Overview](#overview)
- [Installation](#installation)
- [Configuration](#configuration)
- [Authentication](#authentication)
- [Resource Structure](#resource-structure)
- [Error Handling](#error-handling)
- [Testing Approach](#testing-approach)
- [Security Considerations](#security-considerations)
- [Performance Optimizations](#performance-optimizations)
- [Development Roadmap](#development-roadmap)
- [Usage Examples](#usage-examples)

## Overview

The `attio-ruby` gem provides a clean, idiomatic Ruby interface to the Attio API. Built with modern Ruby best practices, it offers:

- Resource-oriented architecture with intuitive method chaining
- Comprehensive error handling with actionable messages
- OAuth 2.0 authentication with scope management
- Thread-safe configuration options
- Connection pooling and retry logic
- Full test coverage with mock support
- Zero runtime dependencies

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

## Configuration

### Global Configuration

```ruby
require 'attio'

Attio.configure do |config|
  config.client_id = 'your_client_id'
  config.client_secret = 'your_client_secret'
  config.redirect_uri = 'https://yourapp.com/oauth/callback'
  
  # Optional configuration
  config.api_base = 'https://api.attio.com' # Default
  config.api_version = 'v2' # Default
  config.timeout = 30 # seconds
  config.max_retries = 3
  config.retry_delay = 1 # seconds (with exponential backoff)
  config.logger = Logger.new(STDOUT) # Optional logging
end
```

### Per-Request Configuration

```ruby
# Override configuration for specific requests
objects = Attio::Object.list(
  limit: 100,
  opts: {
    timeout: 60,
    api_key: 'different_access_token'
  }
)
```

### Environment Variables

The gem automatically reads from environment variables:

```bash
ATTIO_CLIENT_ID=your_client_id
ATTIO_CLIENT_SECRET=your_client_secret
ATTIO_REDIRECT_URI=https://yourapp.com/oauth/callback
```

## Authentication

### OAuth 2.0 Flow

```ruby
# Initialize OAuth client
oauth_client = Attio::OAuth.new(
  client_id: 'your_client_id',
  client_secret: 'your_client_secret',
  redirect_uri: 'https://yourapp.com/oauth/callback'
)

# Generate authorization URL
auth_url = oauth_client.authorization_url(
  scope: ['record_permission:read-write', 'object_configuration:read'],
  state: 'random_state_value'
)

# Exchange authorization code for access token
token_response = oauth_client.exchange_code(
  code: 'authorization_code_from_callback'
)

# Use the access token
Attio.access_token = token_response.access_token

# Token refresh
new_token = oauth_client.refresh_token(
  refresh_token: token_response.refresh_token
)
```

### Scope Management

```ruby
# Available scopes
Attio::OAuth::SCOPES = {
  record_read: 'record_permission:read',
  record_write: 'record_permission:read-write',
  object_config_read: 'object_configuration:read',
  object_config_write: 'object_configuration:read-write',
  user_management_read: 'user_management_permission:read',
  user_management_write: 'user_management_permission:read-write',
  webhook_read: 'webhook:read',
  webhook_write: 'webhook:read-write'
}

# Request multiple scopes
auth_url = oauth_client.authorization_url(
  scope: [:record_write, :object_config_read]
)
```

## Resource Structure

### Core Resources

#### Objects

```ruby
# List all objects
objects = Attio::Object.list(limit: 50, offset: 0)

# Get a specific object
person_object = Attio::Object.retrieve('people')

# Create a custom object
custom_object = Attio::Object.create(
  api_slug: 'projects',
  singular_noun: 'Project',
  plural_noun: 'Projects'
)

# Update an object
updated_object = custom_object.update(
  singular_noun: 'Project Task'
)
```

#### Records

```ruby
# List records for an object
people = Attio::Record.list(
  object: 'people',
  filter: {
    'email_addresses.email_address': 'john@example.com'
  },
  sorts: [
    { attribute: 'created_at', direction: 'desc' }
  ]
)

# Create a record
person = Attio::Record.create(
  object: 'people',
  values: {
    name: [{ value: 'John Doe' }],
    email_addresses: [{ email_address: 'john@example.com' }],
    job_title: [{ value: 'Software Engineer' }]
  }
)

# Update a record
person.update(
  values: {
    job_title: [{ value: 'Senior Software Engineer' }]
  }
)

# Delete a record
person.delete
```

#### Attributes

```ruby
# List attributes for an object
attributes = Attio::Attribute.list(
  parent_object: 'people'
)

# Create a custom attribute
phone_attribute = Attio::Attribute.create(
  parent_object: 'people',
  api_slug: 'mobile_phone',
  title: 'Mobile Phone',
  type: 'phone-number',
  is_required: false,
  is_unique: true
)

# Update an attribute
phone_attribute.update(
  title: 'Primary Phone'
)

# Archive an attribute
phone_attribute.archive
```

#### Lists

```ruby
# Get all lists
lists = Attio::List.list

# Create a list
vip_customers = Attio::List.create(
  name: 'VIP Customers',
  parent_object: 'people'
)

# Add entries to a list
entry = Attio::ListEntry.create(
  list_id: vip_customers.id,
  record_id: person.id
)

# Remove from list
entry.delete
```

#### Workspace Members

```ruby
# List workspace members
members = Attio::WorkspaceMember.list

# Get specific member
member = Attio::WorkspaceMember.retrieve('member_id')
```

#### Webhooks

```ruby
# Create a webhook
webhook = Attio::Webhook.create(
  target_url: 'https://yourapp.com/webhooks/attio',
  events: ['record.created', 'record.updated'],
  filter: {
    object: 'people'
  }
)

# List webhooks
webhooks = Attio::Webhook.list

# Delete webhook
webhook.delete
```

### Service Layer Pattern

```ruby
module Attio
  module Services
    class PersonService
      def self.find_or_create_by_email(email, attributes = {})
        # First try to find existing person
        results = Attio::Record.list(
          object: 'people',
          filter: {
            'email_addresses.email_address': email
          }
        )
        
        if results.any?
          results.first
        else
          # Create new person
          Attio::Record.create(
            object: 'people',
            values: {
              email_addresses: [{ email_address: email }],
              **attributes
            }
          )
        end
      end
      
      def self.bulk_import(people_data)
        results = []
        
        people_data.each_slice(100) do |batch|
          batch.each do |person_data|
            results << create_person(person_data)
          rescue Attio::RateLimitError => e
            sleep(e.retry_after || 60)
            retry
          end
        end
        
        results
      end
    end
  end
end
```

## Error Handling

### Error Hierarchy

```ruby
module Attio
  # Base error class
  class Error < StandardError
    attr_reader :response, :code, :http_status, :request_id
    
    def initialize(message, response: nil)
      @response = response
      @code = response&.dig('error', 'code')
      @http_status = response&.status
      @request_id = response&.headers&.dig('x-request-id')
      super(message)
    end
  end
  
  # Client errors (4xx)
  class ClientError < Error; end
  class BadRequestError < ClientError; end
  class AuthenticationError < ClientError; end
  class ForbiddenError < ClientError; end
  class NotFoundError < ClientError; end
  class ConflictError < ClientError; end
  class UnprocessableEntityError < ClientError; end
  class RateLimitError < ClientError
    attr_reader :retry_after
  end
  
  # Server errors (5xx)
  class ServerError < Error; end
  class InternalServerError < ServerError; end
  class ServiceUnavailableError < ServerError; end
  
  # Other errors
  class ConnectionError < Error; end
  class TimeoutError < Error; end
  class InvalidRequestError < ClientError
    attr_reader :param, :errors
  end
end
```

### Error Handling Examples

```ruby
begin
  person = Attio::Record.create(
    object: 'people',
    values: { name: [{ value: 'John' }] }
  )
rescue Attio::AuthenticationError => e
  # Handle authentication failure
  puts "Authentication failed: #{e.message}"
  puts "Request ID: #{e.request_id}"
rescue Attio::RateLimitError => e
  # Handle rate limiting with retry
  puts "Rate limited. Retry after #{e.retry_after} seconds"
  sleep(e.retry_after)
  retry
rescue Attio::InvalidRequestError => e
  # Handle validation errors
  puts "Validation failed: #{e.message}"
  e.errors.each do |error|
    puts "  #{error['field']}: #{error['message']}"
  end
rescue Attio::Error => e
  # Handle any other Attio API error
  puts "API error: #{e.message} (#{e.code})"
end
```

## Testing Approach

### Mock Support

```ruby
# Enable test mode
Attio.test_mode = true

# Use mock responses
Attio::Testing.mock_response(
  method: :post,
  path: '/v2/objects/people/records',
  response: {
    id: 'rec_123',
    values: {
      name: [{ value: 'Test Person' }]
    }
  }
)

# In your tests
RSpec.describe PersonCreator do
  it 'creates a person' do
    person = Attio::Record.create(
      object: 'people',
      values: { name: [{ value: 'Test Person' }] }
    )
    
    expect(person.id).to eq('rec_123')
  end
end
```

### Test Helpers

```ruby
module Attio
  module Testing
    module Helpers
      def stub_attio_request(method, path, response: {}, status: 200)
        stub_request(method, "https://api.attio.com#{path}")
          .to_return(
            status: status,
            body: response.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end
      
      def with_attio_sandbox
        original_base = Attio.api_base
        Attio.api_base = 'https://sandbox.attio.com'
        yield
      ensure
        Attio.api_base = original_base
      end
    end
  end
end
```

## Security Considerations

### Secure Configuration

```ruby
# Never hardcode credentials
Attio.configure do |config|
  # Use environment variables or secure credential storage
  config.client_id = Rails.application.credentials.attio[:client_id]
  config.client_secret = Rails.application.credentials.attio[:client_secret]
end

# Token storage best practices
class AttioTokenStore
  def self.store(user_id, token_data)
    encrypted_token = encrypt(token_data.to_json)
    Redis.current.setex(
      "attio:token:#{user_id}",
      token_data[:expires_in] - 300, # Expire 5 minutes early
      encrypted_token
    )
  end
  
  def self.retrieve(user_id)
    encrypted_token = Redis.current.get("attio:token:#{user_id}")
    return nil unless encrypted_token
    
    JSON.parse(decrypt(encrypted_token), symbolize_names: true)
  end
end
```

### Webhook Verification

```ruby
module Attio
  class WebhookSignature
    def self.verify(payload:, signature:, secret:)
      expected_signature = OpenSSL::HMAC.hexdigest(
        'SHA256',
        secret,
        payload
      )
      
      # Constant-time comparison to prevent timing attacks
      ActiveSupport::SecurityUtils.secure_compare(
        signature,
        expected_signature
      )
    end
  end
end

# In your webhook controller
def handle_webhook
  signature = request.headers['X-Attio-Signature']
  
  unless Attio::WebhookSignature.verify(
    payload: request.raw_post,
    signature: signature,
    secret: ENV['ATTIO_WEBHOOK_SECRET']
  )
    render status: :unauthorized
    return
  end
  
  # Process webhook...
end
```

## Performance Optimizations

### Connection Pooling

```ruby
module Attio
  class ConnectionManager
    include Singleton
    
    def initialize
      @pools = {}
      @mutex = Mutex.new
    end
    
    def connection_for(config)
      @mutex.synchronize do
        key = config.hash
        @pools[key] ||= ConnectionPool.new(size: 5, timeout: 5) do
          build_connection(config)
        end
      end
    end
    
    private
    
    def build_connection(config)
      Faraday.new(url: config.api_base) do |conn|
        conn.request :json
        conn.response :json
        conn.adapter :net_http_persistent
        conn.options.timeout = config.timeout
        conn.options.open_timeout = config.open_timeout
      end
    end
  end
end
```

### Batch Operations

```ruby
module Attio
  class BatchRequest
    def initialize
      @operations = []
    end
    
    def add(method:, path:, body: nil)
      @operations << {
        method: method,
        path: path,
        body: body
      }
      self
    end
    
    def execute
      Attio.request(
        :post,
        '/v2/batch',
        { operations: @operations }
      )
    end
  end
end

# Usage
batch = Attio::BatchRequest.new
  .add(method: :post, path: '/v2/objects/people/records', body: { values: { name: [{ value: 'John' }] } })
  .add(method: :post, path: '/v2/objects/people/records', body: { values: { name: [{ value: 'Jane' }] } })
  .execute
```

### Caching Strategy

```ruby
module Attio
  class Cache
    def self.fetch(key, expires_in: 300)
      cached = store.get(key)
      return cached if cached
      
      value = yield
      store.set(key, value, ex: expires_in)
      value
    end
    
    def self.clear(pattern = nil)
      if pattern
        keys = store.keys(pattern)
        store.del(*keys) if keys.any?
      else
        store.flushdb
      end
    end
    
    private
    
    def self.store
      @store ||= Redis.current
    end
  end
end

# Usage with objects
def get_object_schema(object_slug)
  Attio::Cache.fetch("object:schema:#{object_slug}", expires_in: 3600) do
    Attio::Object.retrieve(object_slug)
  end
end
```

## Development Roadmap

### Version 0.1.0 (MVP)
- ✅ Basic OAuth 2.0 authentication
- ✅ Core resource classes (Object, Record, Attribute)
- ✅ Error handling framework
- ✅ Configuration management
- ✅ Basic test suite

### Version 0.2.0
- ✅ Complete OAuth flow with token refresh
- ✅ List and workspace member resources
- ✅ Webhook support with signature verification
- ✅ Connection pooling
- ✅ Retry logic with exponential backoff

### Version 0.3.0
- ✅ Batch operations support
- ✅ Advanced filtering and sorting
- ✅ Attribute type validations
- ✅ Comprehensive test helpers
- ✅ Performance instrumentation

### Version 0.4.0
- ⏳ Caching layer with Redis support
- ⏳ Async/concurrent request support
- ⏳ GraphQL API support (if available)
- ⏳ CLI tool for common operations

### Version 1.0.0
- ⏳ Production-ready with stable API
- ⏳ Comprehensive documentation
- ⏳ Performance benchmarks
- ⏳ Migration guides from other CRMs
- ⏳ Enterprise features (SSO, audit logs)

### Future Enhancements
- Real-time event streaming
- Offline queue support
- Advanced data synchronization
- Machine learning integrations
- Multi-region support

## Usage Examples

### Complete Example: Customer Management System

```ruby
require 'attio'

# Configure the client
Attio.configure do |config|
  config.client_id = ENV['ATTIO_CLIENT_ID']
  config.client_secret = ENV['ATTIO_CLIENT_SECRET']
end

# Authenticate
oauth = Attio::OAuth.new
token = oauth.exchange_code(code: params[:code])
Attio.access_token = token.access_token

# Create or update a customer
class CustomerManager
  def self.sync_customer(customer_data)
    # Find or create person
    person = Attio::Services::PersonService.find_or_create_by_email(
      customer_data[:email],
      {
        name: [{ value: customer_data[:name] }],
        job_title: [{ value: customer_data[:title] }]
      }
    )
    
    # Find or create company
    company = find_or_create_company(customer_data[:company])
    
    # Link person to company
    if company
      Attio::Record.create(
        object: 'people-companies',
        values: {
          person: [{ target_object: 'people', target_record_id: person.id }],
          company: [{ target_object: 'companies', target_record_id: company.id }],
          role: [{ value: customer_data[:title] }]
        }
      )
    end
    
    # Add to VIP list if applicable
    if customer_data[:is_vip]
      add_to_vip_list(person)
    end
    
    # Create note about sync
    Attio::Note.create(
      parent_object: 'people',
      parent_record_id: person.id,
      content: "Customer data synced from internal system at #{Time.now}"
    )
    
    person
  rescue Attio::Error => e
    ErrorReporter.report(e, context: { customer_data: customer_data })
    raise
  end
  
  private
  
  def self.find_or_create_company(company_name)
    return nil if company_name.blank?
    
    companies = Attio::Record.list(
      object: 'companies',
      filter: { name: company_name }
    )
    
    if companies.any?
      companies.first
    else
      Attio::Record.create(
        object: 'companies',
        values: {
          name: [{ value: company_name }]
        }
      )
    end
  end
  
  def self.add_to_vip_list(person)
    vip_list = Attio::List.list.find { |l| l.name == 'VIP Customers' }
    
    if vip_list
      Attio::ListEntry.create(
        list_id: vip_list.id,
        record_id: person.id
      )
    end
  end
end

# Webhook handler
class AttioWebhooksController < ApplicationController
  skip_before_action :verify_authenticity_token
  
  def handle
    verify_signature!
    
    event = JSON.parse(request.raw_post)
    
    case event['type']
    when 'record.created'
      handle_record_created(event['data'])
    when 'record.updated'
      handle_record_updated(event['data'])
    end
    
    head :ok
  rescue Attio::WebhookSignature::InvalidSignatureError
    head :unauthorized
  end
  
  private
  
  def verify_signature!
    Attio::WebhookSignature.verify!(
      payload: request.raw_post,
      signature: request.headers['X-Attio-Signature'],
      secret: ENV['ATTIO_WEBHOOK_SECRET']
    )
  end
  
  def handle_record_created(data)
    # Process new record
    RecordCreatedJob.perform_later(data)
  end
  
  def handle_record_updated(data)
    # Process updated record
    RecordUpdatedJob.perform_later(data)
  end
end
```

### Advanced Filtering Example

```ruby
# Complex query with multiple filters
results = Attio::Record.list(
  object: 'people',
  filter: {
    '$and': [
      { 'created_at': { '$gte': '2024-01-01' } },
      { 'job_title': { '$contains': 'Engineer' } },
      {
        '$or': [
          { 'email_addresses.email_address': { '$contains': '@tech.com' } },
          { 'tags': { '$includes': 'technical' } }
        ]
      }
    ]
  },
  sorts: [
    { attribute: 'created_at', direction: 'desc' }
  ],
  limit: 50,
  offset: 0
)

# Process results with pagination
results.auto_paginate do |person|
  puts "#{person.values.name.first.value}: #{person.values.email_addresses.first.email_address}"
end
```

### Error Recovery Example

```ruby
class ResilientAttioClient
  MAX_RETRIES = 3
  
  def self.with_retry(max_attempts = MAX_RETRIES)
    attempts = 0
    
    begin
      attempts += 1
      yield
    rescue Attio::RateLimitError => e
      if attempts < max_attempts
        sleep_time = e.retry_after || (2 ** attempts)
        Rails.logger.warn("Rate limited. Retrying in #{sleep_time} seconds...")
        sleep(sleep_time)
        retry
      else
        raise
      end
    rescue Attio::ServerError => e
      if attempts < max_attempts
        sleep_time = 2 ** attempts
        Rails.logger.warn("Server error. Retrying in #{sleep_time} seconds...")
        sleep(sleep_time)
        retry
      else
        raise
      end
    rescue Attio::ConnectionError => e
      if attempts < max_attempts
        Rails.logger.warn("Connection error. Retrying...")
        sleep(1)
        retry
      else
        raise
      end
    end
  end
end

# Usage
person = ResilientAttioClient.with_retry do
  Attio::Record.create(
    object: 'people',
    values: { name: [{ value: 'John Doe' }] }
  )
end
```

## Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

## License

The gem is available as open source under the terms of the [MIT License](LICENSE).