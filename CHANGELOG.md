# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.2] - 2025-07-27

### Changed
- **BREAKING**: Standardized all resource methods to use keyword arguments for consistency:
  - Attribute: `retrieve(attribute_id:)`, `update(attribute_id:, ...)`, `list(object:)`, `create(object:, name:, type:, ...)`
  - Note: `retrieve(note_id:)`, `create(parent_object:, parent_record_id:, content:, ...)`
  - Task: `update(task_id:, ...)`
  - Comment: Already used keyword arguments
- Improved API consistency across all resources
- All ID parameters now follow consistent naming pattern (e.g., `note_id:` instead of positional parameter)

### Fixed
- API design inconsistency where some resources used positional parameters while others used keyword arguments
- Standardized parameter naming across all resources for better developer experience

## [0.2.1] - 2025-07-27

### Fixed
- Removed unnecessary connection pooling implementation that was redundant with Faraday's built-in capabilities
- Removed unnecessary mutex/thread safety code since Faraday is already thread-safe
- Removed connection_pool gem dependency
- Removed pool_size and pool_timeout configuration options
- Fixed references to VCR in test infrastructure (now using WebMock exclusively)

### Changed
- Simplified Client implementation by removing redundant connection pooling wrapper
- Simplified Configuration class by removing unnecessary mutex synchronization

## [0.2.0] - 2025-07-27

### Added
- Comprehensive YARD documentation for all public APIs
- Connection pooling with configurable pool size and timeout
- Custom request logger that sanitizes sensitive data
- Batch delete operation for records
- Partial update support (PATCH vs PUT)
- Thread-safe client implementation
- Memory-safe auto-pagination with configurable limits
- Better error messages with field-level validation details
- Request retry for 429 and 503 status codes
- Support for net_http_persistent adapter

### Changed
- **BREAKING**: Standardized all Record method signatures to use keyword arguments
- **BREAKING**: Removed deprecated `create_batch` method (use `batch_create`)
- Improved error handling with more descriptive messages
- Enhanced configuration with pool_size and pool_timeout options
- Updated auto-pagination to prevent memory issues with large datasets

### Fixed
- Thread safety issues in configuration and client
- API key potentially being logged in debug mode
- Memory leaks in auto-pagination
- Inconsistent ID extraction logic
- Missing validation for required parameters

### Security
- API keys and sensitive data are now filtered from logs
- Added request sanitization for debug output
- Improved OAuth token handling

## [0.1.0] - 2025-07-27

### Added
- Initial release of the Attio Ruby SDK
- Complete implementation of all Attio API v2 resources:
  - Records (create, read, update, delete, list with filtering/sorting)
  - Lists and List Entries
  - Objects and Attributes
  - Notes
  - Tasks
  - Comments and Threads
  - Webhooks with signature verification
  - Workspace Members
- OAuth 2.0 authentication support
- Thread-safe configuration management
- Comprehensive error handling with specific error types
- Webhook signature verification for security
- VCR-based test suite with high coverage
- Detailed documentation and examples
- Support for Ruby 3.4+