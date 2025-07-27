# Implementation Plan for Missing Attio Resources

## Overview

Based on the existing codebase patterns and API documentation, here's the implementation plan for the missing resources: Entries, Tasks, Comments, and Threads.

## Key Patterns Identified

1. **Base Class**: All resources inherit from `APIResource`
2. **API Operations**: Resources define supported operations using `api_operations`
3. **Testing**: VCR is used for recording HTTP interactions
4. **Error Handling**: Custom error classes in `errors.rb`
5. **ID Structure**: Attio uses nested ID objects (e.g., `{workspace_id: "...", task_id: "..."}`)

## Implementation Order

### Phase 1: Entry Resource (High Priority)
Entries are critical for managing relationships between records and lists.

**Implementation Steps:**
1. Create `spec/unit/attio/resources/entry_spec.rb` with tests
2. Create `lib/attio/resources/entry.rb` implementing:
   - List entries (POST with query)
   - Create entry
   - Retrieve entry
   - Update entry (with overwrite/append options)
   - Delete entry
   - Assert entry by parent
   - List attribute values
3. Add integration tests with VCR cassettes
4. Update main client to include Entry resource

**Special Considerations:**
- Uses POST for listing (with query body)
- Has unique "assert by parent" operation
- Supports both overwrite and append for multiselect values

### Phase 2: Task Resource (High Priority)
Essential CRM functionality for task management.

**Implementation Steps:**
1. Create `spec/unit/attio/resources/task_spec.rb` with tests
2. Create `lib/attio/resources/task.rb` implementing:
   - List tasks (GET with query params)
   - Create task
   - Retrieve task
   - Update task
   - Delete task
3. Add integration tests with VCR cassettes
4. Update main client to include Task resource

**Special Considerations:**
- Complex filtering options (linked records, assignees, completion status)
- Nested relationships (linked_records, assignees)
- Currently only supports plaintext format

### Phase 3: Comment Resource (Medium Priority)
Enables collaboration through comments on records/threads.

**Implementation Steps:**
1. Create `spec/unit/attio/resources/comment_spec.rb` with tests
2. Create `lib/attio/resources/comment.rb` implementing:
   - Create comment
   - Retrieve comment
   - Delete comment (no update operation)
3. Add integration tests with VCR cassettes
4. Update main client to include Comment resource

**Special Considerations:**
- No list or update operations
- Requires thread_id for creation
- Comments are immutable (like Notes)

### Phase 4: Thread Resource (Medium Priority)
Conversation threads containing comments.

**Implementation Steps:**
1. Create `spec/unit/attio/resources/thread_spec.rb` with tests
2. Create `lib/attio/resources/thread.rb` implementing:
   - List threads (GET with query params)
   - Retrieve thread
3. Add integration tests with VCR cassettes
4. Update main client to include Thread resource

**Special Considerations:**
- Read-only resource (no create/update/delete)
- Returns nested comments
- Can filter by record or list entry

## Testing Strategy

### Unit Tests
- Mock HTTP responses
- Test parameter validation
- Test response parsing
- Test error handling

### Integration Tests with VCR
- Record real API interactions
- Test CRUD operations
- Test edge cases
- Test pagination/filtering

### Test Data Setup
```ruby
# Use provided API key for testing
Attio.configure do |config|
  config.api_key = "5d4b3063a71a19b8d12a98f936b6b74d886d05f8580dba40538e019da8871eaf"
end
```

## Code Structure Template

```ruby
# lib/attio/resources/[resource].rb
module Attio
  class [Resource] < APIResource
    api_operations :list, :create, :retrieve, :update, :delete
    
    def self.resource_path
      "[resources]"
    end
    
    # Custom methods as needed
  end
end
```

## Error Handling
- Use existing error classes
- Add new specific errors if needed
- Ensure proper error messages

## Documentation
- Add YARD documentation to all public methods
- Include usage examples
- Document any special behaviors

## Quality Checklist
- [ ] Full test coverage
- [ ] VCR cassettes for all operations
- [ ] Proper error handling
- [ ] Follows Ruby conventions
- [ ] Consistent with existing patterns
- [ ] Documentation complete