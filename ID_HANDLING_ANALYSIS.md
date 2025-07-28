# ID Handling Analysis for Attio Ruby Gem

## Current State Analysis

### 1. Resources with `extract_*_id` Methods

These resources have custom methods to extract IDs from nested hash structures:

- **Comment** - `extract_comment_id` (lines 78-85)
- **Entry** - `extract_entry_id` (lines 219-226)
- **Task** - `extract_task_id` (lines 169-176)
- **Thread** - `extract_thread_id` (lines 71-78)

### 2. Resources that Override `id_key`

These resources specify a custom ID parameter name:

- **List** - `id_key = :list_id` (lines 182-184)
- **Object** - `id_key = :object_id` (lines 34-36)
- **Record** - `id_key = :record_id` (lines 16-18)
- **Thread** - `id_key = :thread_id` (lines 16-18)
- **Webhook** - `id_key = :webhook_id` (lines 13-15)
- **WorkspaceMember** - `id_key = :workspace_member_id` (lines 13-15)

### 3. ID Storage Patterns

#### Nested Hash IDs
Some resources store IDs as nested hashes with workspace and resource-specific IDs:
- **Attribute** - Stores `{attribute_id: "...", object_id: "..."}`
- **Entry** - Stores `{entry_id: "...", list_id: "..."}`
- **List** - Can have `{list_id: "..."}`
- **Record** - Can have `{record_id: "...", object_id: "..."}`

#### String IDs
Other resources use simple string IDs:
- **Comment**
- **Meta** (read-only, no ID manipulation)
- **Note**
- **Task**
- **Thread**
- **Webhook**
- **WorkspaceMember**

### 4. `resource_path` Method Variations

Different patterns for handling IDs in resource paths:

1. **Extract and use specific ID type**:
   ```ruby
   # Attribute, List, Note, Webhook
   attribute_id = id.is_a?(Hash) ? id["attribute_id"] : id
   "#{self.class.resource_path}/#{attribute_id}"
   ```

2. **Use extract method**:
   ```ruby
   # Comment, Entry, Task, Thread
   comment_id = extract_comment_id
   "#{self.class.resource_path}/#{comment_id}"
   ```

3. **Complex path with context**:
   ```ruby
   # Entry (needs list context)
   raise InvalidRequestError, "Cannot generate path without list context" unless list_id
   entry_id = extract_entry_id
   "lists/#{list_id}/entries/#{entry_id}"
   
   # Record (needs object context)
   raise InvalidRequestError, "Cannot generate path without object context" unless object_api_slug
   record_id = id.is_a?(Hash) ? id["record_id"] : id
   "#{self.class.resource_path}/#{object_api_slug}/records/#{record_id}"
   ```

4. **No custom resource_path** (uses base class):
   - Meta
   - Object
   - WorkspaceMember

## Inconsistencies Identified

1. **Mixed Approaches**: Some resources use `extract_*_id` methods while others inline the extraction logic.

2. **Inconsistent Nested Hash Handling**: 
   - Some check for both string and symbol keys (`id[:comment_id] || id["comment_id"]`)
   - Others only check for string keys (`id["attribute_id"]`)

3. **Different Error Messages**: Various error messages for missing IDs/contexts.

4. **id_key Override Not Consistently Used**: Some resources override `id_key` but don't use it consistently in their own methods.

5. **resource_path Implementation**: Some resources need additional context (like Entry needing list_id), making the implementation more complex.

## Normalization Plan

### Phase 1: Standardize ID Extraction

1. **Create a base `extract_id` method in APIResource**:
   ```ruby
   def extract_id(id_type = nil)
     return id unless id.is_a?(Hash)
     
     if id_type
       id[id_type.to_sym] || id[id_type.to_s]
     else
       # Use the class's id_key if no type specified
       key = self.class.id_key
       id[key] || id[key.to_s]
     end
   end
   ```

2. **Update resources to use the standardized method**:
   - Remove individual `extract_*_id` methods
   - Use `extract_id(:comment_id)` or `extract_id` (which uses class's id_key)

### Phase 2: Consistent ID Key Usage

1. **Ensure all resources that need custom ID keys override `id_key`**:
   - Comment should override to `:comment_id`
   - Entry should override to `:entry_id`
   - Task should override to `:task_id`
   - Note should override to `:note_id`

2. **Update base class methods to use `id_key` consistently**

### Phase 3: Standardize resource_path

1. **Create a base implementation that handles common cases**:
   ```ruby
   def resource_path
     raise InvalidRequestError, "Cannot generate path without an ID" unless persisted?
     
     # Allow subclasses to override path generation
     if respond_to?(:build_resource_path, true)
       build_resource_path
     else
       extracted_id = extract_id
       "#{self.class.resource_path}/#{extracted_id}"
     end
   end
   ```

2. **For complex resources (Entry, Record), implement `build_resource_path`**:
   ```ruby
   # Entry
   def build_resource_path
     raise InvalidRequestError, "Cannot generate path without list context" unless list_id
     "lists/#{list_id}/entries/#{extract_id}"
   end
   
   # Record
   def build_resource_path
     raise InvalidRequestError, "Cannot generate path without object context" unless object_api_slug
     "#{self.class.resource_path}/#{object_api_slug}/records/#{extract_id}"
   end
   ```

### Phase 4: Consistent Error Handling

1. **Standardize error messages**:
   - "Cannot generate path without an ID" for missing IDs
   - "Cannot generate path without {context_type} context" for missing context

2. **Create helper methods for common validations**:
   ```ruby
   def validate_persisted!
     raise InvalidRequestError, "Cannot perform operation without an ID" unless persisted?
   end
   
   def validate_context!(context_name, context_value)
     if context_value.nil? || context_value.to_s.empty?
       raise InvalidRequestError, "Cannot perform operation without #{context_name} context"
     end
   end
   ```

### Phase 5: Documentation and Testing

1. **Document the ID handling patterns** in each resource class
2. **Add comprehensive tests** for ID extraction and path generation
3. **Create a developer guide** explaining the ID structure for each resource type

## Benefits of Normalization

1. **Consistency**: Developers can expect the same patterns across all resources
2. **Maintainability**: Changes to ID handling can be made in one place
3. **Reduced Duplication**: Less repeated code across resources
4. **Better Error Handling**: Consistent, informative error messages
5. **Easier Testing**: Standardized behavior is easier to test comprehensively