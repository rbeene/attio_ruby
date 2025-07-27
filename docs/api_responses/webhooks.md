# Webhooks API Responses

## List Webhooks
`GET /v2/webhooks`

```json
{
  "data": []
}
```

## Create Webhook (Error Response)
`POST /v2/webhooks`

**Note**: This example shows a validation error when creating a webhook with invalid parameters.

```json
{
  "status_code": 400,
  "type": "invalid_request_error",
  "code": "validation_type",
  "message": "Body payload validation error.",
  "validation_errors": [
    {
      "code": "invalid",
      "path": ["data", "subscriptions", 0, "filter"],
      "message": "Invalid input"
    }
  ]
}
```