# API Documentation Gap Analysis

## Overview
This report compares the Ruby gem implementation in `lib/attio/resources/` against the API response documentation to identify missing coverage needed for creating accurate WebMock stubs.

## Resources Comparison

### ✅ Documented Resources
1. **Objects** - List, Retrieve
2. **Attributes** - List, Create, Retrieve, Update, Archive, Unarchive
3. **Lists** - List, Create
4. **Records** - List (Companies/People), Create
5. **Webhooks** - List, Create
6. **Workspace Members** - List, Retrieve
7. **Notes** - List

### ❌ Missing Resources (Implemented but Not Documented)
1. **Comment** (`comment.rb`)
2. **Thread** (`thread.rb`)
3. **Task** (`task.rb`)
4. **Entry** (`entry.rb`)
5. **Meta** (`meta.rb`)

## Detailed Gap Analysis

### 1. Objects Resource
**Documented:** ✅ List, ✅ Retrieve
**Missing:**
- ❌ Create operation
- ❌ Update operation
- ❌ Delete operation
- ❌ Error responses for all operations

### 2. Attributes Resource
**Documented:** ✅ List, ✅ Create, ✅ Retrieve, ✅ Update, ✅ Archive, ✅ Unarchive
**Missing:**
- ❌ Delete operation (if supported)
- ❌ Object-scoped attribute operations (`/objects/{object}/attributes`)
- ❌ Error cases for validation failures
- ❌ Response for different attribute types

### 3. Lists Resource
**Documented:** ✅ List, ✅ Create
**Missing:**
- ❌ Retrieve operation
- ❌ Update operation
- ❌ Entry management operations:
  - `GET /lists/{list_id}/entries`
  - `POST /lists/{list_id}/entries`
  - `DELETE /lists/{list_id}/entries/{entry_id}`

### 4. Records Resource
**Documented:** ✅ List (Companies/People), ✅ Create
**Missing:**
- ❌ Retrieve single record (`GET /objects/{object}/records/{record_id}`)
- ❌ Update record (`PUT /objects/{object}/records/{record_id}`)
- ❌ Delete record (`DELETE /objects/{object}/records/{record_id}`)
- ❌ Batch operations:
  - `POST /records/batch`
  - `PUT /records/batch`
- ❌ Query operation (`POST /objects/{object}/records/query`)
- ❌ Search functionality

### 5. Comment Resource (Completely Missing)
**Required Documentation:**
- ❌ Create comment (`POST /comments`)
- ❌ Retrieve comment (`GET /comments/{comment_id}`)
- ❌ Delete comment (`DELETE /comments/{comment_id}`)
- ❌ List comments (if supported)

### 6. Thread Resource (Completely Missing)
**Required Documentation:**
- ❌ List threads (`GET /threads`)
- ❌ Retrieve thread (`GET /threads/{thread_id}`)
- ❌ Query parameters support (record_id, object, entry_id, list)

### 7. Task Resource (Completely Missing)
**Required Documentation:**
- ❌ List tasks (`GET /tasks`)
- ❌ Create task (`POST /tasks`)
- ❌ Retrieve task (`GET /tasks/{task_id}`)
- ❌ Update task (`PATCH /tasks/{task_id}`)
- ❌ Delete task (`DELETE /tasks/{task_id}`)
- ❌ Complete task operation

### 8. Entry Resource (Completely Missing)
**Required Documentation:**
- ❌ List entries (`POST /lists/{list}/entries/query`)
- ❌ Create entry (`POST /lists/{list}/entries`)
- ❌ Retrieve entry (`GET /lists/{list}/entries/{entry_id}`)
- ❌ Update entry (`PATCH /lists/{list}/entries/{entry_id}`)
- ❌ Delete entry (`DELETE /lists/{list}/entries/{entry_id}`)
- ❌ Assert by parent (`PUT /lists/{list}/entries`)
- ❌ List attribute values (`GET /lists/{list}/entries/{entry_id}/attributes/{attribute_id}/values`)

### 9. Meta Resource (Completely Missing)
**Required Documentation:**
- ❌ Identify/self endpoint (`GET /self`)

### 10. Webhooks Resource
**Documented:** ✅ List, ✅ Create
**Missing:**
- ❌ Retrieve webhook
- ❌ Update webhook
- ❌ Delete webhook

### 11. Workspace Members Resource
**Documented:** ✅ List, ✅ Retrieve
**Missing:**
- ❌ Any update operations if supported

### 12. Notes Resource
**Documented:** ✅ List
**Missing:**
- ❌ Create note
- ❌ Retrieve note
- ❌ Update note
- ❌ Delete note

## Error Handling Gaps

The documentation includes some error examples but is missing:
- ❌ Validation errors for each resource type
- ❌ Rate limiting responses
- ❌ Permission/authorization errors
- ❌ Resource conflict errors
- ❌ Batch operation partial failures

## Special Operations Missing

1. **Pagination** - Only first page example shown, missing:
   - ❌ Subsequent pages with cursor
   - ❌ Empty result sets
   - ❌ Last page indicators

2. **Filtering and Sorting** - No examples of:
   - ❌ Complex filter queries
   - ❌ Sort operations
   - ❌ Combined filter + sort + pagination

3. **Batch Operations** - No examples for:
   - ❌ Batch create responses
   - ❌ Batch update responses
   - ❌ Partial success/failure scenarios

## Recommendations

### Priority 1 (Core CRUD Operations)
1. Capture complete CRUD responses for Records
2. Document all Entry operations for Lists
3. Add Meta/self endpoint response
4. Complete Objects CRUD operations

### Priority 2 (Advanced Features)
1. Document Comment and Thread resources
2. Add Task resource operations
3. Capture batch operation responses
4. Add complex query/filter examples

### Priority 3 (Error Handling)
1. Document validation errors for each resource
2. Add authorization/permission errors
3. Include rate limiting responses
4. Show conflict resolution examples

### Priority 4 (Edge Cases)
1. Empty result sets
2. Maximum page sizes
3. Deeply nested data structures
4. Special characters in values

## API Response Capture Script Needed

To complete the documentation, you'll need to capture responses for:

```ruby
# Missing endpoints to capture
endpoints = [
  # Objects
  "POST /v2/objects",
  "PATCH /v2/objects/{id}",
  "DELETE /v2/objects/{id}",
  
  # Records
  "GET /v2/objects/{object}/records/{id}",
  "PUT /v2/objects/{object}/records/{id}",
  "DELETE /v2/objects/{object}/records/{id}",
  "POST /v2/objects/{object}/records/query",
  "POST /v2/records/batch",
  "PUT /v2/records/batch",
  
  # Lists
  "GET /v2/lists/{id}",
  "PATCH /v2/lists/{id}",
  "GET /v2/lists/{id}/entries",
  "POST /v2/lists/{id}/entries",
  "DELETE /v2/lists/{id}/entries/{entry_id}",
  
  # Comments
  "POST /v2/comments",
  "GET /v2/comments/{id}",
  "DELETE /v2/comments/{id}",
  
  # Threads
  "GET /v2/threads",
  "GET /v2/threads/{id}",
  
  # Tasks
  "GET /v2/tasks",
  "POST /v2/tasks",
  "GET /v2/tasks/{id}",
  "PATCH /v2/tasks/{id}",
  "DELETE /v2/tasks/{id}",
  
  # Entries
  "POST /v2/lists/{list}/entries/query",
  "POST /v2/lists/{list}/entries",
  "GET /v2/lists/{list}/entries/{id}",
  "PATCH /v2/lists/{list}/entries/{id}",
  "DELETE /v2/lists/{list}/entries/{id}",
  "PUT /v2/lists/{list}/entries",
  
  # Meta
  "GET /v2/self",
  
  # Notes
  "POST /v2/notes",
  "GET /v2/notes/{id}",
  "PATCH /v2/notes/{id}",
  "DELETE /v2/notes/{id}"
]
```

This comprehensive gap analysis shows that while the basic operations for some resources are documented, there are significant gaps in coverage that would prevent creating complete WebMock stubs for testing the Ruby gem.