# Notes API Responses

## Create Note
`POST /v2/notes`

**Request Body:**
```json
{
  "data": {
    "title": "VCR Test Note",
    "parent_object": "people",
    "parent_record_id": "0174bfac-74b9-41de-b757-c6fa2a68ab00",
    "content": "This is a test note created by VCR",
    "format": "plaintext"
  }
}
```

**Response:**
```json
{
  "data": {
    "id": {
      "workspace_id": "a96c9c20-442b-43cd-a94b-3d4683051661",
      "note_id": "2c06b1a4-e6a4-4c14-a26c-b9af56bcdd64"
    },
    "parent_object": "people",
    "parent_record_id": "0174bfac-74b9-41de-b757-c6fa2a68ab00",
    "title": "VCR Test Note",
    "content_plaintext": "This is a test note created by VCR",
    "content_markdown": "This is a test note created by VCR",
    "tags": [],
    "created_by_actor": {
      "type": "api-token",
      "id": "4c9b8eb9-4b5d-4b27-a37c-6a9ff08bd3ee"
    },
    "created_at": "2025-07-27T01:46:57.651000000Z"
  }
}
```