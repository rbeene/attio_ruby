# Objects API Responses

## List Objects
`GET /v2/objects`

```json
{
  "data": [
    {
      "id": {
        "workspace_id": "a96c9c20-442b-43cd-a94b-3d4683051661",
        "object_id": "2b522f6f-7174-4a69-83c2-cbd745f042cf"
      },
      "api_slug": "users",
      "singular_noun": "User",
      "plural_noun": "Users",
      "created_at": "2025-07-18T13:49:44.655000000Z"
    },
    {
      "id": {
        "workspace_id": "a96c9c20-442b-43cd-a94b-3d4683051661",
        "object_id": "445e7c02-0068-4b3c-8937-aebbf7530920"
      },
      "api_slug": "people",
      "singular_noun": "Person",
      "plural_noun": "People",
      "created_at": "2025-07-18T13:49:44.655000000Z"
    },
    {
      "id": {
        "workspace_id": "a96c9c20-442b-43cd-a94b-3d4683051661",
        "object_id": "c2e36f06-185b-4e53-a057-e33f92b0783b"
      },
      "api_slug": "deals",
      "singular_noun": "Deal",
      "plural_noun": "Deals",
      "created_at": "2025-07-18T13:49:44.655000000Z"
    },
    {
      "id": {
        "workspace_id": "a96c9c20-442b-43cd-a94b-3d4683051661",
        "object_id": "feb7cb84-60fa-4079-acde-2b9cb8af5cf1"
      },
      "api_slug": "companies",
      "singular_noun": "Company",
      "plural_noun": "Companies",
      "created_at": "2025-07-18T13:49:44.655000000Z"
    }
  ]
}
```

## Retrieve Object
`GET /v2/objects/{object_id}`

```json
{
  "data": {
    "id": {
      "workspace_id": "a96c9c20-442b-43cd-a94b-3d4683051661",
      "object_id": "2b522f6f-7174-4a69-83c2-cbd745f042cf"
    },
    "api_slug": "users",
    "singular_noun": "User",
    "plural_noun": "Users",
    "created_at": "2025-07-18T13:49:44.655000000Z"
  }
}
```