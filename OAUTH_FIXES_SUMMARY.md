# OAuth Example Fixes Summary

## Issues Fixed

### 1. **Attribute.list Error**
- **Problem**: `Attributes must be listed for a specific object`
- **Fix**: Changed `Attio::Attribute.list(object: "people")` to `Attio::Attribute.for_object("people")`

### 2. **Record.create Error**
- **Problem**: `An invalid value was passed to attribute with slug "name"`
- **Fix**: Changed from array format `name: [{value: "..."}]` to simple string format `name: "..."`

### 3. **Thread.list Error**
- **Problem**: `Query parameters must query either by a record or by entry`
- **Fix**: Added required query parameters - now queries threads for a specific person record

### 4. **Error Handling Test**
- **Problem**: `Bad request: Path params validation error` with invalid UUID format
- **Fix**: Changed from `"non-existent-id-12345"` to properly formatted UUID `"00000000-0000-0000-0000-000000000000"`

### 5. **Token Introspection Error**
- **Problem**: `OAuth error` - wrong endpoint URL
- **Fix**: Changed OAuth connection URL from `https://api.attio.com` to `https://app.attio.com`
- **Fix**: Updated endpoint paths from `/v2/oauth/*` to `/oauth/*`

### 6. **Task Cleanup Error**
- **Problem**: `bad URI` - task ID was a hash instead of string
- **Fix**: Added logic to extract `task_id` from nested ID structure when it's a hash

## Files Modified

1. `/examples/oauth_flow.rb` - Fixed all test cases in the comprehensive test
2. `/lib/attio/oauth/client.rb` - Fixed OAuth endpoint URLs
3. `/spec/unit/attio/oauth/client_spec.rb` - Updated test stubs to match new URLs

## Test Results

After fixes:
- All 198 RSpec tests passing
- RuboCop clean (no offenses)
- OAuth example comprehensive test should now pass all checks