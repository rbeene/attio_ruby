# Attio API Documentation Reference

This document serves as a quick reference for implementing the missing Attio API resources.

## Entries API

Entries represent relationships between records and lists.

### List Entries
- **Method:** POST
- **Path:** `/v2/lists/{list}/entries/query`
- **Request Body:**
  ```json
  {
    "filter": { "name": "Ada Lovelace" },
    "sorts": [{ "direction": "asc", "attribute": "name", "field": "last_name" }],
    "limit": 500,
    "offset": 0
  }
  ```
- **Response:** Array of entry objects with id, parent_record_id, parent_object, created_at, entry_values

### Create Entry
- **Method:** POST  
- **Path:** `/v2/lists/{list}/entries`
- **Request Body:**
  ```json
  {
    "data": {
      "parent_record_id": "<record_id>",
      "parent_object": "<object_type>",
      "entry_values": { "<attribute_id>": "<value>" }
    }
  }
  ```

### Get Entry
- **Method:** GET
- **Path:** `/v2/lists/{list}/entries/{entry}`

### Update Entry
- **Method:** PATCH
- **Path:** `/v2/lists/{list}/entries/{entry}`
- **Note:** Two methods - overwrite multiselect values or append multiselect values

### Delete Entry
- **Method:** DELETE
- **Path:** `/v2/lists/{list}/entries/{entry}`

### Assert Entry by Parent
- **Method:** PUT
- **Path:** `/v2/lists/{list}/entries`
- **Note:** Creates or updates based on parent record

### List Attribute Values
- **Method:** GET
- **Path:** `/v2/lists/{list}/entries/{entry}/attributes/{attribute}/values`

## Tasks API

### List Tasks
- **Method:** GET
- **Path:** `/v2/tasks`
- **Query Params:** limit, offset, sort, linked_object, linked_record_id, assignee, is_completed
- **Response:** Array of task objects

### Create Task
- **Method:** POST
- **Path:** `/v2/tasks`
- **Request Body:**
  ```json
  {
    "data": {
      "content": "Task description",
      "format": "plaintext",
      "deadline_at": "timestamp",
      "is_completed": false,
      "linked_records": [{ "target_object": "people", "target_record_id": "id" }],
      "assignees": [{ "referenced_actor_type": "workspace-member", "referenced_actor_id": "id" }]
    }
  }
  ```

### Get Task
- **Method:** GET
- **Path:** `/v2/tasks/{task}`

### Update Task
- **Method:** PATCH
- **Path:** `/v2/tasks/{task}`

### Delete Task
- **Method:** DELETE
- **Path:** `/v2/tasks/{task}`

## Comments API

### Create Comment
- **Method:** POST
- **Path:** `/v2/comments`
- **Request Body:**
  ```json
  {
    "data": {
      "format": "plaintext",
      "content": "Comment text",
      "author": { "type": "workspace-member", "id": "id" },
      "created_at": "timestamp",
      "thread_id": "thread-id"
    }
  }
  ```

### Get Comment
- **Method:** GET
- **Path:** `/v2/comments/{comment}`

### Delete Comment
- **Method:** DELETE
- **Path:** `/v2/comments/{comment}`

## Threads API

### List Threads
- **Method:** GET
- **Path:** `/v2/threads`
- **Query Params:** record_id, object, entry_id, list, limit, offset
- **Response:** Array of thread objects with nested comments

### Get Thread
- **Method:** GET
- **Path:** `/v2/threads/{thread}`

## Implementation Notes

### ID Structure
Most resources use nested ID structures:
```ruby
{
  workspace_id: "...",
  <resource>_id: "..." # e.g., task_id, comment_id, thread_id
}
```

### Common Patterns
1. All resources follow RESTful conventions
2. POST requests use `data` wrapper for request body
3. List operations often support filtering, sorting, and pagination
4. Many resources have relationships (e.g., tasks linked to records)

### Required Scopes
Each endpoint requires specific OAuth scopes. Common patterns:
- `:read` for GET operations
- `:read-write` for POST/PATCH/DELETE operations
- Additional configuration scopes for related resources