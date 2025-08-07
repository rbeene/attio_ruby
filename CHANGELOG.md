# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.1] - 2025-08-07

### Fixed
- Minor bug fixes and improvements

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