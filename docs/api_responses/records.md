# Records API Responses

## List People
`POST /v2/objects/people/records/query`

```json
{
  "data": [
    {
      "id": {
        "workspace_id": "a96c9c20-442b-43cd-a94b-3d4683051661",
        "object_id": "445e7c02-0068-4b3c-8937-aebbf7530920",
        "record_id": "0174bfac-74b9-41de-b757-c6fa2a68ab00"
      },
      "created_at": "2025-07-22T15:07:00.895000000Z",
      "web_url": "https://app.attio.com/r-and-k-tech-llc/person/0174bfac-74b9-41de-b757-c6fa2a68ab00",
      "values": {
        "record_id": [
          {
            "active_from": "2025-07-22T15:07:00.895000000Z",
            "active_until": null,
            "created_by_actor": {
              "type": "api-token",
              "id": "4c9b8eb9-4b5d-4b27-a37c-6a9ff08bd3ee"
            },
            "value": "0174bfac-74b9-41de-b757-c6fa2a68ab00",
            "attribute_type": "text"
          }
        ],
        "name": [
          {
            "active_from": "2025-07-22T15:07:00.895000000Z",
            "active_until": null,
            "created_by_actor": {
              "type": "api-token",
              "id": "4c9b8eb9-4b5d-4b27-a37c-6a9ff08bd3ee"
            },
            "first_name": "Phone",
            "last_name": "Test",
            "full_name": "Phone Test",
            "attribute_type": "personal-name"
          }
        ],
        "email_addresses": [
          {
            "active_from": "2025-07-22T15:07:00.895000000Z",
            "active_until": null,
            "created_by_actor": {
              "type": "api-token",
              "id": "4c9b8eb9-4b5d-4b27-a37c-6a9ff08bd3ee"
            },
            "original_email_address": "phone_test_1753196820.501433@example.com",
            "email_address": "phone_test_1753196820.501433@example.com",
            "email_domain": "example.com",
            "email_root_domain": "example.com",
            "email_local_specifier": "phone_test_1753196820.501433",
            "attribute_type": "email-address"
          }
        ],
        "phone_numbers": [
          {
            "active_from": "2025-07-22T15:07:00.895000000Z",
            "active_until": null,
            "created_by_actor": {
              "type": "api-token",
              "id": "4c9b8eb9-4b5d-4b27-a37c-6a9ff08bd3ee"
            },
            "phone_number": "+12125551234",
            "original_phone_number": "+12125551234",
            "country_code": "US",
            "attribute_type": "phone-number"
          }
        ]
      }
    }
  ]
}
```

## Create Record
`POST /v2/objects/{object}/records`

```json
{
  "data": {
    "id": {
      "workspace_id": "a96c9c20-442b-43cd-a94b-3d4683051661",
      "object_id": "445e7c02-0068-4b3c-8937-aebbf7530920",
      "record_id": "a9ccd85f-921f-49c1-8b0a-80b2ae723056"
    },
    "created_at": "2025-07-27T01:45:27.220000000Z",
    "web_url": "https://app.attio.com/r-and-k-tech-llc/person/a9ccd85f-921f-49c1-8b0a-80b2ae723056",
    "values": {
      "record_id": [
        {
          "active_from": "2025-07-27T01:45:27.220000000Z",
          "active_until": null,
          "created_by_actor": {
            "type": "api-token",
            "id": "4c9b8eb9-4b5d-4b27-a37c-6a9ff08bd3ee"
          },
          "value": "a9ccd85f-921f-49c1-8b0a-80b2ae723056",
          "attribute_type": "text"
        }
      ],
      "name": [
        {
          "active_from": "2025-07-27T01:45:27.220000000Z",
          "active_until": null,
          "created_by_actor": {
            "type": "api-token",
            "id": "4c9b8eb9-4b5d-4b27-a37c-6a9ff08bd3ee"
          },
          "first_name": "Test",
          "last_name": "PersonVCR",
          "full_name": "Test PersonVCR",
          "attribute_type": "personal-name"
        }
      ],
      "email_addresses": [],
      "description": [],
      "company": [],
      "job_title": [],
      "avatar_url": [],
      "phone_numbers": [],
      "primary_location": [],
      "created_at": [
        {
          "active_from": "2025-07-27T01:45:27.220000000Z",
          "active_until": null,
          "created_by_actor": {
            "type": "api-token",
            "id": "4c9b8eb9-4b5d-4b27-a37c-6a9ff08bd3ee"
          },
          "value": "2025-07-27T01:45:27.405000000Z",
          "attribute_type": "timestamp"
        }
      ]
    }
  }
}
```