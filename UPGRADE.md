# Upgrade Guide

## Upgrading to 0.2.0

Version 0.2.0 includes several breaking changes to improve API consistency and thread safety. This guide will help you upgrade your code.

### Breaking Changes

#### 1. Record Method Signatures

All `Record` class methods now use consistent keyword arguments. This affects the following methods:

**Before (0.1.0):**
```ruby
# Mixed positional and keyword arguments
Attio::Record.retrieve("rec_123", object: "people")
Attio::Record.update("rec_123", object: "people", data: { values: { name: "New Name" } })
Attio::Record.delete("rec_123", object: "people")
```

**After (0.2.0):**
```ruby
# All keyword arguments
Attio::Record.retrieve(record_id: "rec_123", object: "people")
Attio::Record.update(record_id: "rec_123", object: "people", values: { name: "New Name" })
Attio::Record.delete(record_id: "rec_123", object: "people")
```

#### 2. Batch Operations

The `create_batch` method has been removed in favor of the more consistently named `batch_create`:

**Before (0.1.0):**
```ruby
Attio::Record.create_batch(
  object: "people",
  records: [
    { values: { name: "John" } },
    { values: { name: "Jane" } }
  ]
)
```

**After (0.2.0):**
```ruby
Attio::Record.batch_create(
  object: "people",
  records: [
    { values: { name: "John" } },
    { values: { name: "Jane" } }
  ]
)
```

#### 3. Update Method Parameters

The `update` method now takes `values` directly instead of wrapped in a `data` hash:

**Before (0.1.0):**
```ruby
Attio::Record.update(
  record_id: "rec_123",
  object: "people",
  data: { values: { name: "New Name" } }
)
```

**After (0.2.0):**
```ruby
Attio::Record.update(
  record_id: "rec_123",
  object: "people",
  values: { name: "New Name" }
)
```

### New Features

#### 1. Connection Pooling

Connection pooling is now enabled by default. You can configure it:

```ruby
Attio.configure do |config|
  config.api_key = "your_api_key"
  config.pool_size = 10      # Default: 5
  config.pool_timeout = 10   # Default: 5 seconds
end
```

#### 2. Batch Delete

New batch delete operation for efficient bulk deletions:

```ruby
result = Attio::Record.batch_delete(
  object: "people",
  record_ids: ["rec_123", "rec_456", "rec_789"]
)
puts "Deleted: #{result[:deleted].count}"
puts "Failed: #{result[:failed].count}"
```

#### 3. Partial Updates

You can now choose between partial updates (PATCH) and full replacement (PUT):

```ruby
# Partial update (default) - only sends changed fields
record[:name] = "New Name"
record.save

# Full replacement - sends all fields
record.save(partial: false)
```

#### 4. Enhanced Error Messages

Error messages now include more detail, especially for validation errors:

```ruby
begin
  Attio::Record.create(object: "people", values: { invalid_field: "value" })
rescue Attio::UnprocessableEntityError => e
  puts e.message  # "Validation failed: invalid_field: is not a valid attribute"
end
```

#### 5. Request Logging

Debug logging now sanitizes sensitive data:

```ruby
Attio.configure do |config|
  config.debug = true
  config.logger = Logger.new(STDOUT)
end
# API keys and tokens are automatically filtered from logs
```

### Migration Script

Here's a script to help identify code that needs updating:

```ruby
# find_deprecated_usage.rb
deprecated_patterns = [
  /Record\.retrieve\([^:]/,              # Positional arguments in retrieve
  /Record\.update\([^:]/,                # Positional arguments in update
  /Record\.delete\([^:]/,                # Positional arguments in delete
  /create_batch/,                        # Deprecated method name
  /data:\s*{\s*values:/                  # Old update format
]

Dir.glob("**/*.rb").each do |file|
  next if file.include?("vendor/")
  
  content = File.read(file)
  deprecated_patterns.each_with_index do |pattern, index|
    if content.match?(pattern)
      puts "#{file}: Contains deprecated pattern ##{index + 1}"
    end
  end
end
```

### Compatibility Layer

If you need to maintain compatibility temporarily, you can create a compatibility layer:

```ruby
# config/initializers/attio_compatibility.rb
module AttioCompatibility
  module RecordCompatibility
    def retrieve(id_or_options, opts = {})
      if id_or_options.is_a?(String)
        # Old style: Record.retrieve("id", object: "people")
        super(record_id: id_or_options, **opts)
      else
        # New style: Record.retrieve(record_id: "id", object: "people")
        super(**id_or_options, **opts)
      end
    end
    
    def create_batch(**args)
      # Redirect old method to new method
      batch_create(**args)
    end
  end
end

Attio::Record.singleton_class.prepend(AttioCompatibility::RecordCompatibility)
```

### Testing Your Upgrade

After upgrading, run your test suite with warnings enabled to catch any issues:

```bash
RUBYOPT="-W2" bundle exec rspec
```

### Need Help?

If you encounter any issues during the upgrade, please:
1. Check the [CHANGELOG](CHANGELOG.md) for additional details
2. Review the updated [examples](examples/) directory
3. Open an issue on [GitHub](https://github.com/rbeene/attio_ruby/issues)