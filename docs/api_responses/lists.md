# Lists API Responses

## List Lists
`GET /v2/lists`

```json
{
  "data": [
    {
      "id": {
        "workspace_id": "a96c9c20-442b-43cd-a94b-3d4683051661",
        "list_id": "b557d074-c549-4807-bc01-c4fd74cb419c"
      },
      "api_slug": "customer_success",
      "created_at": "2025-07-18T13:50:25.142000000Z",
      "name": "Customer Success",
      "workspace_access": null,
      "workspace_member_access": [
        {
          "level": "full-access",
          "workspace_member_id": "1757c0bb-f8e6-4013-b41d-2e49a3ef2c6f"
        }
      ],
      "parent_object": ["companies"],
      "created_by_actor": {
        "type": "workspace-member",
        "id": "1757c0bb-f8e6-4013-b41d-2e49a3ef2c6f"
      }
    },
    {
      "id": {
        "workspace_id": "a96c9c20-442b-43cd-a94b-3d4683051661",
        "list_id": "a1bd2c90-1c6d-4b1b-8c48-79ae46b5bc2c"
      },
      "api_slug": "test_api_list",
      "created_at": "2025-07-27T01:13:08.392000000Z",
      "name": "Test API List",
      "workspace_access": "full-access",
      "workspace_member_access": [],
      "parent_object": ["people"],
      "created_by_actor": {
        "type": "api-token",
        "id": "4c9b8eb9-4b5d-4b27-a37c-6a9ff08bd3ee"
      }
    }
  ]
}
```

## Create List
`POST /v2/lists`

```json
{
  "data": {
    "id": {
      "workspace_id": "a96c9c20-442b-43cd-a94b-3d4683051661",
      "list_id": "fa542089-565f-407e-847d-96a8a0592d67"
    },
    "api_slug": "vcr_test_list_test_20250727072457_dfbc38fb",
    "created_at": "2025-07-27T11:24:57.302000000Z",
    "name": "VCR Test List test_20250727072457_dfbc38fb",
    "workspace_access": "full-access",
    "workspace_member_access": [],
    "parent_object": ["people"],
    "created_by_actor": {
      "type": "api-token",
      "id": "4c9b8eb9-4b5d-4b27-a37c-6a9ff08bd3ee"
    }
  }
}
```