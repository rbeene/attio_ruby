# Attributes API Responses

## List Attributes
`GET /v2/objects/{object}/attributes`

```json
{
  "data": [
    {
      "id": {
        "workspace_id": "a96c9c20-442b-43cd-a94b-3d4683051661",
        "object_id": "445e7c02-0068-4b3c-8937-aebbf7530920",
        "attribute_id": "19438e2e-a3cb-48ec-a1e7-8a3a29b1c950"
      },
      "title": "Record ID",
      "description": null,
      "api_slug": "record_id",
      "type": "text",
      "is_system_attribute": true,
      "is_writable": false,
      "is_required": false,
      "is_unique": true,
      "is_multiselect": false,
      "is_default_value_enabled": false,
      "is_archived": false,
      "default_value": null,
      "relationship": null,
      "created_at": "2025-07-18T13:49:44.710000000Z",
      "config": {
        "currency": {
          "default_currency_code": null,
          "display_type": null
        },
        "record_reference": {
          "allowed_object_ids": null
        }
      }
    },
    {
      "id": {
        "workspace_id": "a96c9c20-442b-43cd-a94b-3d4683051661",
        "object_id": "445e7c02-0068-4b3c-8937-aebbf7530920",
        "attribute_id": "54812ea7-4f67-4a26-adb1-945706126f18"
      },
      "title": "Name",
      "description": null,
      "api_slug": "name",
      "type": "personal-name",
      "is_system_attribute": true,
      "is_writable": true,
      "is_required": false,
      "is_unique": false,
      "is_multiselect": false,
      "is_default_value_enabled": false,
      "is_archived": false,
      "default_value": null,
      "relationship": null,
      "created_at": "2025-07-18T13:49:44.710000000Z",
      "config": {
        "currency": {
          "default_currency_code": null,
          "display_type": null
        },
        "record_reference": {
          "allowed_object_ids": null
        }
      }
    }
  ]
}
```

## Create Attribute
`POST /v2/objects/{object}/attributes`

```json
{
  "data": {
    "id": {
      "workspace_id": "a96c9c20-442b-43cd-a94b-3d4683051661",
      "object_id": "445e7c02-0068-4b3c-8937-aebbf7530920",
      "attribute_id": "10ea9ef1-6857-4af1-834e-a5c8864afc12"
    },
    "title": "Test Attribute 1753625180",
    "description": "Test attribute for documentation",
    "api_slug": "test_attribute_1753625180",
    "type": "text",
    "is_system_attribute": false,
    "is_writable": true,
    "is_required": false,
    "is_unique": false,
    "is_multiselect": false,
    "is_default_value_enabled": false,
    "is_archived": false,
    "default_value": null,
    "relationship": null,
    "created_at": "2025-07-27T14:06:20.785000000Z",
    "config": {
      "currency": {
        "default_currency_code": null,
        "display_type": null
      },
      "record_reference": {
        "allowed_object_ids": null
      }
    }
  }
}
```

## Retrieve Attribute
`GET /v2/objects/{object}/attributes/{attribute_id}`

```json
{
  "data": {
    "id": {
      "workspace_id": "a96c9c20-442b-43cd-a94b-3d4683051661",
      "object_id": "445e7c02-0068-4b3c-8937-aebbf7530920",
      "attribute_id": "10ea9ef1-6857-4af1-834e-a5c8864afc12"
    },
    "title": "Test Attribute 1753625180",
    "description": "Test attribute for documentation",
    "api_slug": "test_attribute_1753625180",
    "type": "text",
    "is_system_attribute": false,
    "is_writable": true,
    "is_required": false,
    "is_unique": false,
    "is_multiselect": false,
    "is_default_value_enabled": false,
    "is_archived": false,
    "default_value": null,
    "relationship": null,
    "created_at": "2025-07-27T14:06:20.785000000Z",
    "config": {
      "currency": {
        "default_currency_code": null,
        "display_type": null
      },
      "record_reference": {
        "allowed_object_ids": null
      }
    }
  }
}
```

## Update Attribute
`PATCH /v2/objects/{object}/attributes/{attribute_id}`

```json
{
  "data": {
    "id": {
      "workspace_id": "a96c9c20-442b-43cd-a94b-3d4683051661",
      "object_id": "445e7c02-0068-4b3c-8937-aebbf7530920",
      "attribute_id": "10ea9ef1-6857-4af1-834e-a5c8864afc12"
    },
    "title": "Test Attribute 1753625180",
    "description": "Updated description at 2025-07-27 10:06:21 -0400",
    "api_slug": "test_attribute_1753625180",
    "type": "text",
    "is_system_attribute": false,
    "is_writable": true,
    "is_required": false,
    "is_unique": false,
    "is_multiselect": false,
    "is_default_value_enabled": false,
    "is_archived": false,
    "default_value": null,
    "relationship": null,
    "created_at": "2025-07-27T14:06:20.785000000Z",
    "config": {
      "currency": {
        "default_currency_code": null,
        "display_type": null
      },
      "record_reference": {
        "allowed_object_ids": null
      }
    }
  }
}
```

## Archive Attribute (Error Response)
`POST /v2/attributes/{attribute_id}/archive`

**Note**: This endpoint returned a 404 error. The correct archive endpoint may be different.

```json
{
  "error": "Attio::NotFoundError",
  "message": "Resource not found",
  "response_body": {
    "status": 404,
    "headers": {
      "date": "Sun, 27 Jul 2025 14:06:21 GMT",
      "content-type": "application/json; charset=utf-8"
    },
    "body": {
      "status_code": 404,
      "type": "invalid_request_error",
      "code": "not_found",
      "message": "Could not find endpoint \"POST /v2/attributes/10ea9ef1-6857-4af1-834e-a5c8864afc12/archive\"."
    }
  }
}
```