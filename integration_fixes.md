# Integration Test Fixes

## Summary
We need to fix all 81 failing integration tests. The user has provided the real API key and wants all tests fixed without interruption.

**API Key**: `5d4b3063a71a19b8d12a98f936b6b74d886d05f8580dba40538e019da8871eaf`

## Current Status

### ✅ Fixed: Record Integration Tests (11/11 passing)
- Fixed company name format (simple string, not hash with "value" key)
- Fixed domains format (single hash, not array)
- Fixed company relationship (returns string "companies", not object)
- Fixed job title format (simple string, not hash with "value" key)
- Fixed error types (BadRequestError vs InvalidRequestError)
- Fixed delete test to store ID before destroy
- Fixed search test to handle both hash and array formats for name
- Fixed filter tests to use unique emails
- Fixed not found error test to use valid UUID format

### ❌ List Integration Tests (Not yet run)
- Need to check if API key is being set correctly
- May have similar data format issues as Record tests

### ❌ Entry Integration Tests (Not yet run)
- Already has API key hardcoded in spec
- May need to fix data formats

### ❌ Note Integration Tests (Not yet run)
- Need to check API key setup
- May need format fixes

### ❌ Webhook Integration Tests (Not yet run)
- Need to check API key setup
- May need format fixes

### ❌ OAuth Integration Tests (Not yet run)
- OAuth flow may be different
- Need to check API key setup

### ❌ Object Integration Tests (Not yet run)
- Need to check API key setup
- May need format fixes

## Key Learnings from Record Tests

1. **API Response Formats**:
   - Company `name`: Simple string, not hash
   - Person `name`: Array of objects with first_name, last_name, full_name
   - `domains`: Single hash with "domain" key, not array
   - `email_addresses`: Array of strings
   - `phone_numbers`: Array of objects with original_phone_number and country_code
   - `job_title`: Simple string, not hash with "value"

2. **Phone Number Validation**:
   - Must use valid phone numbers (not 555 prefix)
   - Format: `{original_phone_number: "+12125551234", country_code: "US"}`

3. **Error Types**:
   - API returns `BadRequestError` for validation errors, not `InvalidRequestError`
   - Invalid UUID format returns `BadRequestError`, not `NotFoundError`

4. **Record Processing**:
   - The `extract_value` method in Record class extracts single-element arrays
   - This means attributes can be either arrays or single values depending on context

5. **Search Behavior**:
   - Search can return many results, need unique identifiers
   - Name format in search results includes metadata (active_from, created_by_actor, etc.)

## Fix Strategy

1. **API Key Setup**: Ensure all specs set the API key correctly:
   ```ruby
   before do
     Attio.configure do |config|
       config.api_key = ENV["ATTIO_API_KEY"] || "5d4b3063a71a19b8d12a98f936b6b74d886d05f8580dba40538e019da8871eaf"
     end
   end
   ```

2. **Data Format Fixes**: Apply learnings from Record tests to other specs:
   - Check all name formats
   - Check all email formats (should be arrays)
   - Check all error expectations
   - Check ID handling after destroy operations

3. **Systematic Approach**:
   - Run each test suite individually
   - Fix data format issues based on actual API responses
   - Update error expectations to match actual errors
   - Handle ID/reference formats correctly

## Next Steps

1. Run List integration tests and fix issues
2. Run Entry integration tests and fix issues
3. Run Note integration tests and fix issues
4. Run Webhook integration tests and fix issues
5. Run OAuth integration tests and fix issues
6. Run Object integration tests and fix issues
7. Run all integration tests together to verify

The user wants this done without interruption: "We need to fix all integration tests. Do not stop until it is done."