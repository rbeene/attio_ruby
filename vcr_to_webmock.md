# VCR to WebMock Migration Guide

This document provides a comprehensive guide for converting VCR cassettes to WebMock stubs in the Attio Ruby SDK tests. It links to actual API responses documented in `api_response_documentation.md` and identifies gaps noted in `api_documentation_gap_analysis.md`.

## Table of Contents

1. [Migration Strategy](#migration-strategy)
2. [Resource Documentation Links](#resource-documentation-links)
3. [WebMock Stub Templates](#webmock-stub-templates)
4. [Resource-by-Resource Guide](#resource-by-resource-guide)
5. [Common Patterns](#common-patterns)
6. [Missing Coverage](#missing-coverage)

## Migration Strategy

1. **Phase 1**: Replace VCR with WebMock using documented responses
2. **Phase 2**: Add missing endpoint coverage
3. **Phase 3**: Increase test coverage to 90%+

## Resource Documentation Links

Each resource section below links to the corresponding API responses in our documentation:

### Documented Resources
- **Objects**: [API Responses](docs/api_responses/objects.md) ✅ List, Retrieve
- **Attributes**: [API Responses](docs/api_responses/attributes.md) ✅ List, Create, Retrieve, Update, Archive*, Unarchive*
- **Lists**: [API Responses](docs/api_responses/lists.md) ✅ List, Create
- **Records**: [API Responses](docs/api_responses/records.md) ✅ List (Companies/People), Create
- **Webhooks**: [API Responses](docs/api_responses/webhooks.md) ✅ List, Create
- **Workspace Members**: [API Responses](docs/api_responses/workspace_members.md) ✅ List, Retrieve
- **Notes**: [API Responses](docs/api_responses/notes.md) ✅ List
- **Errors**: [API Responses](docs/api_responses/errors.md) ✅ 404, 422, 400, 401
- **Pagination**: [API Responses](docs/api_responses/pagination.md) ✅ First Page

*Note: Archive/Unarchive endpoints returned 404 errors - need to verify correct endpoint paths

### Missing Resources (No Documentation)
- **Comment** - No API responses captured
- **Thread** - No API responses captured
- **Task** - No API responses captured
- **Entry** - No API responses captured
- **Meta** - No API responses captured

## WebMock Stub Templates

### Basic Response Structure

All list responses follow this pattern:
```ruby
stub_request(:get, "https://api.attio.com/v2/#{resource_path}")
  .to_return(
    status: 200,
    body: {
      data: [...],
      has_more: false,
      cursor: nil
    }.to_json,
    headers: { 'Content-Type' => 'application/json' }
  )
```

All single resource responses follow this pattern:
```ruby
stub_request(:get, "https://api.attio.com/v2/#{resource_path}/#{id}")
  .to_return(
    status: 200,
    body: {
      data: {...}
    }.to_json,
    headers: { 'Content-Type' => 'application/json' }
  )
```

### Error Response Structure

```ruby
stub_request(:get, "https://api.attio.com/v2/#{resource_path}/non-existent")
  .to_return(
    status: 404,
    body: {
      status_code: 404,
      type: "invalid_request_error",
      code: "not_found",
      message: "Resource not found"
    }.to_json,
    headers: { 'Content-Type' => 'application/json' }
  )
```

## Resource-by-Resource Guide

### 1. Objects (`spec/attio/resources/object_spec.rb`)

**Documented Operations:**
- `GET /v2/objects` - [View Response](docs/api_responses/objects.md#list-objects)
- `GET /v2/objects/{object_id}` - [View Response](docs/api_responses/objects.md#retrieve-object)

**Missing Operations:**
- `POST /v2/objects` - Create
- `PATCH /v2/objects/{object_id}` - Update
- `DELETE /v2/objects/{object_id}` - Delete

**WebMock Example:**
```ruby
# List objects
stub_request(:get, "https://api.attio.com/v2/objects")
  .to_return(
    status: 200,
    body: File.read('spec/fixtures/objects/list.json')
  )
```

### 2. Attributes (`spec/attio/resources/attribute_spec.rb`)

**Documented Operations:**
- `GET /v2/objects/{object}/attributes` - [View Response](docs/api_responses/attributes.md#list-attributes)
- `POST /v2/objects/{object}/attributes` - [View Response](docs/api_responses/attributes.md#create-attribute)
- `GET /v2/objects/{object}/attributes/{attribute_id}` - [View Response](docs/api_responses/attributes.md#retrieve-attribute)
- `PATCH /v2/objects/{object}/attributes/{attribute_id}` - [View Response](docs/api_responses/attributes.md#update-attribute)

**Issues Found:**
- Archive/Unarchive endpoints returned 404 - need correct paths

**WebMock Example:**
```ruby
# Create attribute
stub_request(:post, "https://api.attio.com/v2/objects/people/attributes")
  .with(body: hash_including(data: hash_including(title: "Test Attribute")))
  .to_return(
    status: 200,
    body: File.read('spec/fixtures/attributes/create.json')
  )
```

### 3. Lists (`spec/attio/resources/list_spec.rb`)

**Documented Operations:**
- `GET /v2/lists` - [View Response](docs/api_responses/lists.md#list-lists)
- `POST /v2/lists` - [View Response](docs/api_responses/lists.md#create-list)

**Missing Operations:**
- `GET /v2/lists/{list_id}` - Retrieve
- `PATCH /v2/lists/{list_id}` - Update
- `DELETE /v2/lists/{list_id}` - Delete
- Entry management operations

**WebMock Example:**
```ruby
# Create list
stub_request(:post, "https://api.attio.com/v2/lists")
  .with(body: hash_including(data: hash_including(name: "Test List")))
  .to_return(
    status: 200,
    body: File.read('spec/fixtures/lists/create.json')
  )
```

### 4. Records (`spec/attio/resources/record_spec.rb`)

**Documented Operations:**
- `GET /v2/objects/companies/records` - [View Response](docs/api_responses/records.md#list-companies)
- `GET /v2/objects/people/records` - [View Response](docs/api_responses/records.md#list-people)
- `POST /v2/objects/{object}/records` - [View Response](docs/api_responses/records.md#create-record)

**Missing Operations:**
- `GET /v2/objects/{object}/records/{record_id}` - Retrieve
- `PUT /v2/objects/{object}/records/{record_id}` - Update
- `DELETE /v2/objects/{object}/records/{record_id}` - Delete
- Batch operations
- Query operations

**WebMock Example:**
```ruby
# List records
stub_request(:get, "https://api.attio.com/v2/objects/people/records")
  .to_return(
    status: 200,
    body: File.read('spec/fixtures/records/list_people.json')
  )
```

### 5. Webhooks (`spec/attio/resources/webhook_spec.rb`)

**Documented Operations:**
- `GET /v2/webhooks` - [View Response](docs/api_responses/webhooks.md#list-webhooks)
- `POST /v2/webhooks` - [View Response](docs/api_responses/webhooks.md#create-webhook)

**Missing Operations:**
- `GET /v2/webhooks/{webhook_id}` - Retrieve
- `PATCH /v2/webhooks/{webhook_id}` - Update
- `DELETE /v2/webhooks/{webhook_id}` - Delete

### 6. Workspace Members (`spec/attio/resources/workspace_member_spec.rb`)

**Documented Operations:**
- `GET /v2/workspace_members` - [View Response](docs/api_responses/workspace_members.md#list-workspace-members)
- `GET /v2/workspace_members/{workspace_member_id}` - [View Response](docs/api_responses/workspace_members.md#retrieve-workspace-member)

### 7. Notes (`spec/attio/resources/note_spec.rb`)

**Documented Operations:**
- `GET /v2/notes` - [View Response](docs/api_responses/notes.md#list-notes)

**Missing Operations:**
- `POST /v2/notes` - Create
- `GET /v2/notes/{note_id}` - Retrieve
- `PATCH /v2/notes/{note_id}` - Update
- `DELETE /v2/notes/{note_id}` - Delete

## Common Patterns

### 1. ID Structure
All resources use composite IDs:
```ruby
{
  "workspace_id": "a96c9c20-442b-43cd-a94b-3d4683051661",
  "object_id": "2b522f6f-7174-4a69-83c2-cbd745f042cf"  # Plus resource-specific ID
}
```

### 2. Timestamps
All timestamps use microsecond precision:
```ruby
"created_at": "2025-07-18T13:49:44.655000000Z"
```

### 3. List Response Structure
```ruby
{
  "data": [...],
  "has_more": false,
  "cursor": null
}
```

### 4. Error Response Structure
```ruby
{
  "status_code": 404,
  "type": "invalid_request_error",
  "code": "not_found",
  "message": "Error message here"
}
```

### 5. Validation Errors (422)
```ruby
{
  "status_code": 400,
  "type": "invalid_request_error",
  "code": "validation_type",
  "message": "Body payload validation error.",
  "validation_errors": [
    {
      "code": "invalid_type",
      "path": ["data", "field_name"],
      "message": "Required",
      "expected": "string",
      "received": "undefined"
    }
  ]
}
```

## Missing Coverage

Based on [api_documentation_gap_analysis.md](api_documentation_gap_analysis.md), we need to capture responses for:

### Priority 1 - Core CRUD Operations
1. **Records**: Retrieve, Update, Delete
2. **Lists**: Retrieve, Update, Delete, Entry operations
3. **Objects**: Create, Update, Delete
4. **Meta**: Self endpoint

### Priority 2 - Advanced Features
1. **Comment**: All operations
2. **Thread**: All operations
3. **Task**: All operations
4. **Entry**: All operations
5. Batch operations for Records
6. Query/Search functionality

### Priority 3 - Error Handling
1. Rate limiting responses
2. Permission/authorization errors
3. Resource conflict errors
4. Batch operation partial failures

## Next Steps

1. **Update existing specs** using the documented responses
2. **Create fixture files** from api_response_documentation.md
3. **Add WebMock stubs** following the patterns above
4. **Capture missing responses** for undocumented endpoints
5. **Write new tests** for missing coverage

## Helper Methods

Consider creating shared spec helpers:

```ruby
# spec/support/webmock_helpers.rb
module WebMockHelpers
  def stub_attio_list(resource, response_file)
    stub_request(:get, "https://api.attio.com/v2/#{resource}")
      .to_return(
        status: 200,
        body: File.read("spec/fixtures/#{resource}/#{response_file}.json"),
        headers: { 'Content-Type' => 'application/json' }
      )
  end
  
  def stub_attio_get(resource, id, response_file)
    stub_request(:get, "https://api.attio.com/v2/#{resource}/#{id}")
      .to_return(
        status: 200,
        body: File.read("spec/fixtures/#{resource}/#{response_file}.json"),
        headers: { 'Content-Type' => 'application/json' }
      )
  end
  
  def stub_attio_error(method, path, status, error_response)
    stub_request(method, "https://api.attio.com/v2/#{path}")
      .to_return(
        status: status,
        body: error_response.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )
  end
end
```