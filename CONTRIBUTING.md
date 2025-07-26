# Contributing to Attio Ruby SDK

First off, thank you for considering contributing to the Attio Ruby SDK! It's people like you that make this SDK a great tool for the Ruby community.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [How Can I Contribute?](#how-can-i-contribute)
  - [Reporting Bugs](#reporting-bugs)
  - [Suggesting Enhancements](#suggesting-enhancements)
  - [Pull Requests](#pull-requests)
- [Development Setup](#development-setup)
- [Style Guide](#style-guide)
- [Testing](#testing)
- [Documentation](#documentation)
- [Release Process](#release-process)

## Code of Conduct

This project and everyone participating in it is governed by our Code of Conduct. By participating, you are expected to uphold this code. Please report unacceptable behavior to support@attio.com.

## Getting Started

1. Fork the repository on GitHub
2. Clone your fork locally
3. Set up your development environment (see [Development Setup](#development-setup))
4. Create a branch for your changes
5. Make your changes
6. Add tests for your changes
7. Ensure all tests pass
8. Submit a pull request

## How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check existing issues as you might find out that you don't need to create one. When you are creating a bug report, please include as many details as possible:

**Bug Report Template:**

```markdown
**Description**
A clear and concise description of what the bug is.

**To Reproduce**
Steps to reproduce the behavior:
1. Configure the client with '...'
2. Call method '....'
3. See error

**Expected behavior**
A clear and concise description of what you expected to happen.

**Actual behavior**
What actually happened, including any error messages.

**Environment:**
 - Ruby version: [e.g. 3.1.0]
 - Gem version: [e.g. 1.0.0]
 - OS: [e.g. macOS 12.0]

**Additional context**
Add any other context about the problem here.
```

### Suggesting Enhancements

Enhancement suggestions are tracked as GitHub issues. When creating an enhancement suggestion, please include:

- A clear and descriptive title
- A detailed description of the proposed enhancement
- Explain why this enhancement would be useful
- List any alternatives you've considered
- Provide examples of how the feature would be used

### Pull Requests

1. Ensure your code follows the [Style Guide](#style-guide)
2. Include appropriate test coverage
3. Update documentation as needed
4. Add a changelog entry in the Unreleased section
5. Ensure CI passes on your pull request
6. Request review from maintainers

**Pull Request Template:**

```markdown
**Description**
Brief description of the changes in this PR.

**Motivation and Context**
Why is this change required? What problem does it solve?
Fixes #(issue)

**How Has This Been Tested?**
Describe the tests that you ran to verify your changes.

**Types of changes**
- [ ] Bug fix (non-breaking change which fixes an issue)
- [ ] New feature (non-breaking change which adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to change)

**Checklist:**
- [ ] My code follows the code style of this project
- [ ] My change requires a change to the documentation
- [ ] I have updated the documentation accordingly
- [ ] I have added tests to cover my changes
- [ ] All new and existing tests passed
```

## Development Setup

1. **Install Ruby**
   ```bash
   rbenv install 3.1.0  # or use your preferred Ruby version manager
   rbenv local 3.1.0
   ```

2. **Clone and setup the repository**
   ```bash
   git clone https://github.com/yourusername/attio-ruby.git
   cd attio-ruby
   bundle install
   ```

3. **Set up environment variables**
   ```bash
   cp .env.example .env
   # Edit .env with your test API credentials
   ```

4. **Run tests to verify setup**
   ```bash
   bundle exec rspec
   ```

5. **Start development console**
   ```bash
   bin/console
   ```

## Style Guide

### Ruby Style

We use RuboCop to enforce consistent code style. Run RuboCop before submitting:

```bash
bundle exec rubocop
bundle exec rubocop -a  # Auto-fix violations
```

Key style points:
- Use 2 spaces for indentation (no tabs)
- Use snake_case for variables and methods
- Use CamelCase for classes and modules
- Limit lines to 100 characters
- Use meaningful variable and method names
- Add frozen string literal comments to all files

### Git Commit Messages

- Use the present tense ("Add feature" not "Added feature")
- Use the imperative mood ("Move cursor to..." not "Moves cursor to...")
- Limit the first line to 72 characters or less
- Reference issues and pull requests liberally after the first line

Example:
```
Add batch update support for records

- Implement update_batch method in Record class
- Add progress callback support
- Include comprehensive error handling
- Add tests for edge cases

Fixes #123
```

## Testing

### Running Tests

```bash
# Run all tests
bundle exec rspec

# Run specific test file
bundle exec rspec spec/unit/resources/record_spec.rb

# Run tests matching a pattern
bundle exec rspec -e "batch operations"

# Run with coverage report
COVERAGE=true bundle exec rspec
```

### Writing Tests

- Write unit tests for all new functionality
- Aim for 100% code coverage for new code
- Use descriptive test names that explain what is being tested
- Group related tests using `describe` and `context`
- Use `let` and `subject` to reduce duplication
- Mock external API calls in unit tests

Example test structure:
```ruby
RSpec.describe Attio::Record do
  describe ".create" do
    context "with valid parameters" do
      it "creates a new record" do
        # test implementation
      end
    end

    context "with invalid parameters" do
      it "raises InvalidRequestError" do
        # test implementation
      end
    end
  end
end
```

### Integration Tests

Integration tests require a valid API key:

```bash
ATTIO_API_KEY=your_test_key RUN_INTEGRATION_TESTS=true bundle exec rspec spec/integration
```

**Important:** Never commit real API keys. Use test/sandbox accounts for integration tests.

## Documentation

### Code Documentation

We use YARD for API documentation. Document all public methods:

```ruby
# Creates a new record in the specified object
#
# @param object [String] The API slug of the object (e.g., "people", "companies")
# @param values [Hash] The attribute values for the new record
# @param opts [Hash] Additional options for the request
# @option opts [String] :api_key Override the default API key
# @option opts [Integer] :timeout Override the default timeout
#
# @return [Attio::Record] The created record
#
# @raise [Attio::Errors::InvalidRequestError] If the values are invalid
# @raise [Attio::Errors::NotFoundError] If the object doesn't exist
#
# @example Create a new person
#   person = Attio::Record.create(
#     object: "people",
#     values: {
#       name: "John Doe",
#       email_addresses: "john@example.com"
#     }
#   )
def self.create(object:, values:, opts: {})
  # implementation
end
```

Generate documentation:
```bash
bundle exec yard doc
open doc/index.html
```

### README Updates

Update the README when adding:
- New features
- Breaking changes
- Configuration options
- Usage examples

## Release Process

1. **Update version number**
   ```ruby
   # lib/attio/version.rb
   module Attio
     VERSION = "1.1.0"  # Follow semantic versioning
   end
   ```

2. **Update CHANGELOG.md**
   - Move unreleased changes to a new version section
   - Add release date
   - Follow [Keep a Changelog](https://keepachangelog.com/) format

3. **Create release commit**
   ```bash
   git add -A
   git commit -m "Release version 1.1.0"
   git push origin main
   ```

4. **Create and push tag**
   ```bash
   git tag -a v1.1.0 -m "Release version 1.1.0"
   git push origin v1.1.0
   ```

5. **Build and release gem**
   ```bash
   gem build attio-ruby.gemspec
   gem push attio-ruby-1.1.0.gem
   ```

6. **Create GitHub release**
   - Go to GitHub releases page
   - Create release from tag
   - Copy changelog entries
   - Publish release

## Questions?

If you have questions about contributing, please:

1. Check existing issues and pull requests
2. Review the documentation
3. Open a discussion on GitHub
4. Contact the maintainers

Thank you for contributing to the Attio Ruby SDK!