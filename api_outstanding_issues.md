# Outstanding API Issues for Attio Ruby Gem

## Priority 1: Critical API Design Issues

### 1. APIResource#save Only Works for Updates
**Problem**: The `save` method cannot create new records, only update existing ones. This breaks Ruby conventions where `save` should handle both create and update operations (like ActiveRecord).

**Impact**: Developers expect `save` to work for new objects, leading to confusion and errors.

**Solution**: Implement logic to detect if the resource is persisted and call either create or update accordingly.

### 2. Confusing ID Structure
**Problem**: IDs are sometimes nested hashes (`{workspace_id: "...", object_id: "...", record_id: "..."}`) and sometimes strings, causing complexity throughout the codebase.

**Impact**: 
- Developers must handle both formats
- Extra extraction logic needed everywhere
- Increased chance of bugs

**Solution**: Normalize ID handling with a consistent interface that works with both formats transparently.

### 3. Record Path Generation is Fragile
**Problem**: Path generation relies on multiple attributes (object_api_slug, id extraction) and can fail in various ways.

**Impact**: Runtime errors when attributes are missing or in unexpected formats.

**Solution**: Centralize and harden path generation with proper validation and error messages.

## Priority 2: Security Issues

### 4. Missing Webhook Signature Verification
**Problem**: While WebhookSignature utility exists, it's not integrated into the main webhook handling flow.

**Impact**: Security vulnerability - webhooks could be spoofed.

**Solution**: Add built-in signature verification to webhook processing with clear documentation.

## Priority 3: Code Quality Issues

### 5. Magic Strings and Numbers
**Problem**: Hard-coded values throughout the codebase without constants.

**Examples**:
- HTTP methods as strings
- Status codes as numbers
- API paths as strings
- Default timeouts as numbers

**Solution**: Extract all magic values to constants.

### 6. Missing Input Validation
**Problem**: Many methods don't validate inputs before making API calls, leading to cryptic errors from the API.

**Impact**: Poor developer experience with unhelpful error messages.

**Solution**: Add validation with clear error messages for all public methods.

### 7. Complex Nested Conditionals
**Problem**: Several methods have deeply nested conditionals that are hard to follow.

**Impact**: Reduced maintainability and increased bug risk.

**Solution**: Refactor complex methods using guard clauses and extracted methods.

## Priority 4: Performance Issues

### 8. Inefficient Deep Copying
**Problem**: Attributes are deep copied on every change, which could impact performance with large objects.

**Impact**: Memory and CPU overhead for large attribute sets.

**Solution**: Implement copy-on-write or more efficient change tracking.

### 9. No Lazy Loading for Related Resources
**Problem**: Related resources are always fetched immediately, even if not needed.

**Impact**: Unnecessary API calls and slower performance.

**Solution**: Implement lazy loading for relationships.

## Implementation Plan

1. **Phase 1**: Fix save method and ID handling (Priority 1 items 1-3)
2. **Phase 2**: Add webhook signature verification (Priority 2)
3. **Phase 3**: Extract magic values and add validation (Priority 3 items 5-6)
4. **Phase 4**: Refactor complex methods (Priority 3 item 7)
5. **Phase 5**: Performance optimizations (Priority 4)

## Success Metrics

- All resources support create via `save` method
- Consistent ID handling across all resources
- Zero magic strings/numbers in the codebase
- All public methods validate inputs
- Webhook signature verification enabled by default
- Performance benchmarks show no regression