# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.4] - 2025-08-08

### Added
- **TimeFilterable Concern**: New reusable module for time-based filtering across resources
  - Methods like `created_after`, `created_before`, `updated_after`, `updated_before`
  - Support for `created_between` and `updated_between` with date ranges
  - Automatic date/time parsing and formatting
- **TimePeriod Utility**: Comprehensive time period handling
  - Support for standard periods (today, yesterday, this_week, last_week, this_month, etc.)
  - Quarter calculations (this_quarter, last_quarter, etc.)
  - Custom date range support
  - Flexible period parsing from strings
- **CurrencyFormatter Utility**: Professional currency formatting
  - Support for 40+ international currencies
  - Proper symbol placement and formatting per currency
  - Thousand separators and decimal handling
- **Enhanced Deal Resource**: Major improvements to Deal functionality
  - Time-based filtering methods: `recently_created`, `recently_updated`, `created_this_month`, etc.
  - Monetary value methods: `amount`, `currency`, `formatted_amount`, `raw_value`
  - Advanced querying: `high_value`, `low_value`, `with_value`, `without_value`
  - Assignment filters: `assigned_to`, `unassigned`
  - Metrics calculation: `metrics_for_period` with optimized API calls
  - Pipeline velocity: `average_days_to_close`, `conversion_rate`
  - Stage helpers: `stage_display_name` for human-readable stage names

### Fixed
- Fixed `ListObject#first` method to accept optional argument like Ruby's `Array#first`
- Updated currency formatting test expectations to properly include cents
- Corrected integration test for workspace member retrieval

### Changed
- Improved Deal stage handling to align with actual Attio API behavior
- Optimized `metrics_for_period` to use targeted API calls instead of loading all deals
- Simplified monetary value extraction to use consistent `currency_value` format

### Testing
- Added comprehensive test coverage for all new features
- 336 new tests for TimeFilterable concern
- 415 tests for TimePeriod utility
- 162 tests for CurrencyFormatter
- Extensive integration tests for Deal improvements
- Test coverage remains high at ~90%

## [0.1.3] - 2025-08-07

### Fixed
- Added `lib/attio-ruby.rb` to fix Rails auto-require issue. The gem can now be auto-required by Rails/Bundler without needing `require: 'attio'` in the Gemfile.

## [0.1.2] - 2025-08-07

### Added
- Deal status configuration system for customizing won/lost/open statuses
- `Deal.in_stage` method to query deals by multiple stage names
- Convenience class methods: `Deal.won`, `Deal.lost`, `Deal.open_deals`
- Instance methods for deals: `current_status`, `status_changed_at`, `won_at`, `closed_at`
- Improved `won?`, `lost?`, and `open?` methods that use configuration

### Fixed
- WorkspaceMember.active and WorkspaceMember.admins methods argument passing issue
- Configuration arrays are now properly duplicated to avoid frozen array issues

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