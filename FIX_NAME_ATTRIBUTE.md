# Name Attribute Bug in Attio Ruby Gem

## Problem

The gem's normalization logic converts simple string values to `{value: "string"}` format, but the Attio API expects the `name` attribute for people to have a specific structure:

```json
{
  "name": [
    {
      "first_name": "John",
      "last_name": "Smith", 
      "full_name": "John Smith"
    }
  ]
}
```

## Current Behavior

When users do:
```ruby
Attio::Record.create(
  object: "people",
  values: { name: "John Smith" }
)
```

The gem converts it to:
```json
{
  "name": [{"value": "John Smith"}]
}
```

Which causes an API error: "An invalid value was passed to attribute with slug 'name'"

## Examples Affected

1. `/examples/basic_usage.rb` - Uses `name: "John Doe"`
2. `/examples/batch_operations.rb` - Uses `name: "Test Person 1"`
3. All integration tests that create people records
4. Documentation examples in README

## Workaround

Until fixed, users must manually provide the correct format:
```ruby
Attio::Record.create(
  object: "people",
  values: {
    name: [{
      first_name: "John",
      last_name: "Smith",
      full_name: "John Smith"
    }],
    email_addresses: ["john@example.com"]
  }
)
```

## Proposed Fix

The `normalize_values` method in `/lib/attio/resources/record.rb` needs special handling for the name attribute when the object is "people". It could:

1. Parse "John Smith" and split into first/last names
2. Or require users to always provide the full structure
3. Or add a helper method like `name_value(first: "John", last: "Smith")`

This is a breaking issue that prevents creating person records using the documented examples.