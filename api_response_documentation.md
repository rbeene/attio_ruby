# Attio API Response Documentation

This document contains actual API responses captured from the Attio API.
Generated on: 2025-07-27 10:06:25
API Key (partial): 5d4b3063a71...

## Table of Contents
- [Objects](#objects)
- [Attributes](#attributes)
- [Lists](#lists)
- [Records](#records)
- [Webhooks](#webhooks)
- [Workspace Members](#workspace-members)
- [Notes](#notes)
- [Errors](#errors)
- [Pagination](#pagination)

## Objects

### List
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

### Retrieve
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

## Attributes

### List
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
    },
    {
      "id": {
        "workspace_id": "a96c9c20-442b-43cd-a94b-3d4683051661",
        "object_id": "445e7c02-0068-4b3c-8937-aebbf7530920",
        "attribute_id": "34ff8623-ac16-4286-9ce4-c5f7c430a4a2"
      },
      "title": "Email addresses",
      "description": null,
      "api_slug": "email_addresses",
      "type": "email-address",
      "is_system_attribute": true,
      "is_writable": true,
      "is_required": false,
      "is_unique": true,
      "is_multiselect": true,
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
        "attribute_id": "23c9bdb3-a97b-4f83-bbaf-a1520aeca865"
      },
      "title": "Description",
      "description": null,
      "api_slug": "description",
      "type": "text",
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
    },
    {
      "id": {
        "workspace_id": "a96c9c20-442b-43cd-a94b-3d4683051661",
        "object_id": "445e7c02-0068-4b3c-8937-aebbf7530920",
        "attribute_id": "fdc04ee2-85bb-4a38-8e10-080daf1ed766"
      },
      "title": "Company",
      "description": null,
      "api_slug": "company",
      "type": "record-reference",
      "is_system_attribute": true,
      "is_writable": true,
      "is_required": false,
      "is_unique": false,
      "is_multiselect": false,
      "is_default_value_enabled": false,
      "is_archived": false,
      "default_value": null,
      "relationship": {
        "id": {
          "workspace_id": "a96c9c20-442b-43cd-a94b-3d4683051661",
          "object_id": "feb7cb84-60fa-4079-acde-2b9cb8af5cf1",
          "attribute_id": "cc50550d-8883-4c89-a539-081cb63bd60f"
        }
      },
      "created_at": "2025-07-18T13:49:44.710000000Z",
      "config": {
        "currency": {
          "default_currency_code": null,
          "display_type": null
        },
        "record_reference": {
          "allowed_object_ids": [
            "feb7cb84-60fa-4079-acde-2b9cb8af5cf1"
          ]
        }
      }
    },
    {
      "id": {
        "workspace_id": "a96c9c20-442b-43cd-a94b-3d4683051661",
        "object_id": "445e7c02-0068-4b3c-8937-aebbf7530920",
        "attribute_id": "ecf4f16c-ba01-46ca-b86d-7b211aa91bfa"
      },
      "title": "Job title",
      "description": null,
      "api_slug": "job_title",
      "type": "text",
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
    },
    {
      "id": {
        "workspace_id": "a96c9c20-442b-43cd-a94b-3d4683051661",
        "object_id": "445e7c02-0068-4b3c-8937-aebbf7530920",
        "attribute_id": "e97c2220-23ac-46b8-86ad-1f892ac15738"
      },
      "title": "Avatar URL",
      "description": null,
      "api_slug": "avatar_url",
      "type": "text",
      "is_system_attribute": true,
      "is_writable": false,
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
    },
    {
      "id": {
        "workspace_id": "a96c9c20-442b-43cd-a94b-3d4683051661",
        "object_id": "445e7c02-0068-4b3c-8937-aebbf7530920",
        "attribute_id": "955a1d55-1cb9-4acb-9761-57396f4a437c"
      },
      "title": "Phone numbers",
      "description": null,
      "api_slug": "phone_numbers",
      "type": "phone-number",
      "is_system_attribute": true,
      "is_writable": true,
      "is_required": false,
      "is_unique": false,
      "is_multiselect": true,
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
        "attribute_id": "30850cec-51dd-45bf-ae1e-81da21226d52"
      },
      "title": "Primary location",
      "description": null,
      "api_slug": "primary_location",
      "type": "location",
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
    },
    {
      "id": {
        "workspace_id": "a96c9c20-442b-43cd-a94b-3d4683051661",
        "object_id": "445e7c02-0068-4b3c-8937-aebbf7530920",
        "attribute_id": "aeb94274-39a9-4a32-9cee-f01d317d9747"
      },
      "title": "AngelList",
      "description": null,
      "api_slug": "angellist",
      "type": "text",
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
    },
    {
      "id": {
        "workspace_id": "a96c9c20-442b-43cd-a94b-3d4683051661",
        "object_id": "445e7c02-0068-4b3c-8937-aebbf7530920",
        "attribute_id": "af4e068d-a5a9-4445-ba27-765d3989aa53"
      },
      "title": "Facebook",
      "description": null,
      "api_slug": "facebook",
      "type": "text",
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
    },
    {
      "id": {
        "workspace_id": "a96c9c20-442b-43cd-a94b-3d4683051661",
        "object_id": "445e7c02-0068-4b3c-8937-aebbf7530920",
        "attribute_id": "7fd33a54-568b-4b5c-b4a4-04ca7cfd9d0c"
      },
      "title": "Instagram",
      "description": null,
      "api_slug": "instagram",
      "type": "text",
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
    },
    {
      "id": {
        "workspace_id": "a96c9c20-442b-43cd-a94b-3d4683051661",
        "object_id": "445e7c02-0068-4b3c-8937-aebbf7530920",
        "attribute_id": "77efe3b6-3118-4ebb-8f5a-da60a99e6e8b"
      },
      "title": "LinkedIn",
      "description": null,
      "api_slug": "linkedin",
      "type": "text",
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
    },
    {
      "id": {
        "workspace_id": "a96c9c20-442b-43cd-a94b-3d4683051661",
        "object_id": "445e7c02-0068-4b3c-8937-aebbf7530920",
        "attribute_id": "5a40d2d3-2cd0-4687-b85b-342a65a44aa1"
      },
      "title": "Twitter",
      "description": null,
      "api_slug": "twitter",
      "type": "text",
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
    },
    {
      "id": {
        "workspace_id": "a96c9c20-442b-43cd-a94b-3d4683051661",
        "object_id": "445e7c02-0068-4b3c-8937-aebbf7530920",
        "attribute_id": "da00e0da-81cd-44ac-a519-482306febd5a"
      },
      "title": "Twitter follower count",
      "description": null,
      "api_slug": "twitter_follower_count",
      "type": "number",
      "is_system_attribute": true,
      "is_writable": false,
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
    },
    {
      "id": {
        "workspace_id": "a96c9c20-442b-43cd-a94b-3d4683051661",
        "object_id": "445e7c02-0068-4b3c-8937-aebbf7530920",
        "attribute_id": "9df98c3c-9c86-4c6b-94fa-cc156f3dbc89"
      },
      "title": "First calendar interaction",
      "description": null,
      "api_slug": "first_calendar_interaction",
      "type": "interaction",
      "is_system_attribute": true,
      "is_writable": false,
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
    },
    {
      "id": {
        "workspace_id": "a96c9c20-442b-43cd-a94b-3d4683051661",
        "object_id": "445e7c02-0068-4b3c-8937-aebbf7530920",
        "attribute_id": "4abe67e6-8662-47f8-a4eb-511e9e343124"
      },
      "title": "Last calendar interaction",
      "description": null,
      "api_slug": "last_calendar_interaction",
      "type": "interaction",
      "is_system_attribute": true,
      "is_writable": false,
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
    },
    {
      "id": {
        "workspace_id": "a96c9c20-442b-43cd-a94b-3d4683051661",
        "object_id": "445e7c02-0068-4b3c-8937-aebbf7530920",
        "attribute_id": "a35ce2fe-4827-4d17-82a3-15fbec430b95"
      },
      "title": "Next calendar interaction",
      "description": null,
      "api_slug": "next_calendar_interaction",
      "type": "interaction",
      "is_system_attribute": true,
      "is_writable": false,
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
    },
    {
      "id": {
        "workspace_id": "a96c9c20-442b-43cd-a94b-3d4683051661",
        "object_id": "445e7c02-0068-4b3c-8937-aebbf7530920",
        "attribute_id": "845d8b46-9e6e-4bfd-b398-fbcab3d7953e"
      },
      "title": "First email interaction",
      "description": null,
      "api_slug": "first_email_interaction",
      "type": "interaction",
      "is_system_attribute": true,
      "is_writable": false,
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
    },
    {
      "id": {
        "workspace_id": "a96c9c20-442b-43cd-a94b-3d4683051661",
        "object_id": "445e7c02-0068-4b3c-8937-aebbf7530920",
        "attribute_id": "06492cde-776c-4589-af36-cefae743e739"
      },
      "title": "Last email interaction",
      "description": null,
      "api_slug": "last_email_interaction",
      "type": "interaction",
      "is_system_attribute": true,
      "is_writable": false,
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
    },
    {
      "id": {
        "workspace_id": "a96c9c20-442b-43cd-a94b-3d4683051661",
        "object_id": "445e7c02-0068-4b3c-8937-aebbf7530920",
        "attribute_id": "aaed80c5-f6c2-436d-aed9-7c1880e98ac2"
      },
      "title": "First interaction",
      "description": null,
      "api_slug": "first_interaction",
      "type": "interaction",
      "is_system_attribute": true,
      "is_writable": false,
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
    },
    {
      "id": {
        "workspace_id": "a96c9c20-442b-43cd-a94b-3d4683051661",
        "object_id": "445e7c02-0068-4b3c-8937-aebbf7530920",
        "attribute_id": "7ea07e6f-4f63-45e9-86ec-00007915d267"
      },
      "title": "Last interaction",
      "description": null,
      "api_slug": "last_interaction",
      "type": "interaction",
      "is_system_attribute": true,
      "is_writable": false,
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
    },
    {
      "id": {
        "workspace_id": "a96c9c20-442b-43cd-a94b-3d4683051661",
        "object_id": "445e7c02-0068-4b3c-8937-aebbf7530920",
        "attribute_id": "361140cb-d453-4c66-9ec8-ae4daa2e09c7"
      },
      "title": "Next interaction",
      "description": null,
      "api_slug": "next_interaction",
      "type": "interaction",
      "is_system_attribute": true,
      "is_writable": false,
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
    },
    {
      "id": {
        "workspace_id": "a96c9c20-442b-43cd-a94b-3d4683051661",
        "object_id": "445e7c02-0068-4b3c-8937-aebbf7530920",
        "attribute_id": "6ca5dbc1-9319-4f13-b08b-eb095b385328"
      },
      "title": "Connection strength (legacy)",
      "description": null,
      "api_slug": "strongest_connection_strength_legacy",
      "type": "number",
      "is_system_attribute": true,
      "is_writable": false,
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
    },
    {
      "id": {
        "workspace_id": "a96c9c20-442b-43cd-a94b-3d4683051661",
        "object_id": "445e7c02-0068-4b3c-8937-aebbf7530920",
        "attribute_id": "d9415c1f-d76e-472a-a108-9a537dd0e7c8"
      },
      "title": "Connection strength",
      "description": null,
      "api_slug": "strongest_connection_strength",
      "type": "select",
      "is_system_attribute": true,
      "is_writable": false,
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
    },
    {
      "id": {
        "workspace_id": "a96c9c20-442b-43cd-a94b-3d4683051661",
        "object_id": "445e7c02-0068-4b3c-8937-aebbf7530920",
        "attribute_id": "abace7fe-9f9a-4bb4-a5a0-5bbc26dbb632"
      },
      "title": "Strongest connection",
      "description": null,
      "api_slug": "strongest_connection_user",
      "type": "actor-reference",
      "is_system_attribute": true,
      "is_writable": false,
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
    },
    {
      "id": {
        "workspace_id": "a96c9c20-442b-43cd-a94b-3d4683051661",
        "object_id": "445e7c02-0068-4b3c-8937-aebbf7530920",
        "attribute_id": "da6d98b6-66fb-439b-a561-e000ebad4855"
      },
      "title": "Associated deals",
      "description": "Deal records associated with a Person record",
      "api_slug": "associated_deals",
      "type": "record-reference",
      "is_system_attribute": true,
      "is_writable": true,
      "is_required": false,
      "is_unique": false,
      "is_multiselect": true,
      "is_default_value_enabled": false,
      "is_archived": false,
      "default_value": null,
      "relationship": {
        "id": {
          "workspace_id": "a96c9c20-442b-43cd-a94b-3d4683051661",
          "object_id": "c2e36f06-185b-4e53-a057-e33f92b0783b",
          "attribute_id": "85354900-2ae5-464c-9e12-b5a8c3b56864"
        }
      },
      "created_at": "2025-07-18T13:49:44.710000000Z",
      "config": {
        "currency": {
          "default_currency_code": null,
          "display_type": null
        },
        "record_reference": {
          "allowed_object_ids": [
            "c2e36f06-185b-4e53-a057-e33f92b0783b"
          ]
        }
      }
    },
    {
      "id": {
        "workspace_id": "a96c9c20-442b-43cd-a94b-3d4683051661",
        "object_id": "445e7c02-0068-4b3c-8937-aebbf7530920",
        "attribute_id": "601bd173-ea39-44b8-9e53-3385d11aa912"
      },
      "title": "Associated users",
      "description": "User records associated with a Person record",
      "api_slug": "associated_users",
      "type": "record-reference",
      "is_system_attribute": true,
      "is_writable": true,
      "is_required": false,
      "is_unique": false,
      "is_multiselect": true,
      "is_default_value_enabled": false,
      "is_archived": false,
      "default_value": null,
      "relationship": {
        "id": {
          "workspace_id": "a96c9c20-442b-43cd-a94b-3d4683051661",
          "object_id": "2b522f6f-7174-4a69-83c2-cbd745f042cf",
          "attribute_id": "5d3542cc-8265-48e3-8da2-f988fedaab8d"
        }
      },
      "created_at": "2025-07-18T13:49:44.710000000Z",
      "config": {
        "currency": {
          "default_currency_code": null,
          "display_type": null
        },
        "record_reference": {
          "allowed_object_ids": [
            "2b522f6f-7174-4a69-83c2-cbd745f042cf"
          ]
        }
      }
    },
    {
      "id": {
        "workspace_id": "a96c9c20-442b-43cd-a94b-3d4683051661",
        "object_id": "445e7c02-0068-4b3c-8937-aebbf7530920",
        "attribute_id": "c058182b-40c7-4426-8bbf-1ff5e4194192"
      },
      "title": "Created at",
      "description": null,
      "api_slug": "created_at",
      "type": "timestamp",
      "is_system_attribute": true,
      "is_writable": false,
      "is_required": false,
      "is_unique": false,
      "is_multiselect": false,
      "is_default_value_enabled": true,
      "is_archived": false,
      "default_value": {
        "type": "dynamic",
        "template": "PT0S"
      },
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
        "attribute_id": "6feb5ddd-2508-4477-8db0-8e8646c36aea"
      },
      "title": "Created by",
      "description": null,
      "api_slug": "created_by",
      "type": "actor-reference",
      "is_system_attribute": true,
      "is_writable": false,
      "is_required": false,
      "is_unique": false,
      "is_multiselect": false,
      "is_default_value_enabled": true,
      "is_archived": false,
      "default_value": {
        "type": "dynamic",
        "template": "current-user"
      },
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
        "attribute_id": "8cfa9309-677c-4991-9968-e06ba7a7e89d"
      },
      "title": "Test Field 1753579750",
      "description": "A test field created by SDK",
      "api_slug": "test_field_1753579750",
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
      "created_at": "2025-07-27T01:29:10.778000000Z",
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
        "attribute_id": "f80f27ad-a92f-41af-b841-145e2c178e5b"
      },
      "title": "Test Field 1753579757",
      "description": "A test field created by SDK",
      "api_slug": "test_field_1753579757",
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
      "created_at": "2025-07-27T01:29:17.822000000Z",
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
        "attribute_id": "bdb7e29c-430b-4bc7-9ea9-4b1ece14554b"
      },
      "title": "Test Field 1753579789",
      "description": "A test field created by SDK",
      "api_slug": "test_field_1753579789",
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
      "created_at": "2025-07-27T01:29:49.357000000Z",
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
        "attribute_id": "5c07ca61-f87c-4fda-a29c-1f0f433f036e"
      },
      "title": "Test Field 1753579806",
      "description": "Updated description",
      "api_slug": "test_field_1753579806",
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
      "created_at": "2025-07-27T01:30:06.318000000Z",
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
        "attribute_id": "24cad828-c257-4332-96e2-970f0e678800"
      },
      "title": "VCR Test Field",
      "description": "A test field created by VCR",
      "api_slug": "vcr_test_field",
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
      "created_at": "2025-07-27T01:46:58.968000000Z",
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
        "attribute_id": "f24cc1fb-fd0c-407a-b49f-244bcab6cf6c"
      },
      "title": "VCR Test Field test_20250727072501_e7721eff",
      "description": "A test field created by VCR",
      "api_slug": "vcr_test_field_test_20250727072501_e7721eff",
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
      "created_at": "2025-07-27T11:25:02.352000000Z",
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
        "attribute_id": "89649962-5631-44bb-994e-a499e49ad6ff"
      },
      "title": "VCR Test Field test_20250727072508_70f59051",
      "description": "A test field created by VCR",
      "api_slug": "vcr_test_field_test_20250727072508_70f59051",
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
      "created_at": "2025-07-27T11:25:08.265000000Z",
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
        "attribute_id": "fc27835e-b953-46fb-9800-522176da531e"
      },
      "title": "VCR Test Field test_20250727113155_f041f2fc",
      "description": "A test field created by VCR",
      "api_slug": "vcr_test_field_test_20250727113155_f041f2fc",
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
      "created_at": "2025-07-27T11:31:55.422000000Z",
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
        "attribute_id": "07ed7639-9351-47e7-8e5e-ea1612484748"
      },
      "title": "VCR Test Field test_20250727114341_06688ab2",
      "description": "A test field created by VCR",
      "api_slug": "vcr_test_field_test_20250727114341_06688ab2",
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
      "created_at": "2025-07-27T11:43:41.480000000Z",
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
        "attribute_id": "2859a4c1-dfdf-49b4-95b0-272667a88a3c"
      },
      "title": "VCR Test Field test_20250727122353_2a670633",
      "description": "A test field created by VCR",
      "api_slug": "vcr_test_field_test_20250727122353_2a670633",
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
      "created_at": "2025-07-27T12:23:53.998000000Z",
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
        "attribute_id": "fcd68c5e-96f2-4cbe-8e69-5f24483bf3d8"
      },
      "title": "VCR Test Field test_20250727122700_59c5f585",
      "description": "A test field created by VCR",
      "api_slug": "vcr_test_field_test_20250727122700_59c5f585",
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
      "created_at": "2025-07-27T12:27:00.491000000Z",
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
        "attribute_id": "f3c6b1ff-d79a-466c-b67d-3f5b6fc31104"
      },
      "title": "VCR Test Field test_20250727124126_3054268f",
      "description": "A test field created by VCR",
      "api_slug": "vcr_test_field_test_20250727124126_3054268f",
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
      "created_at": "2025-07-27T12:41:27.175000000Z",
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
        "attribute_id": "267b63ae-6ee2-4c92-984b-f9172352937e"
      },
      "title": "VCR Test Field test_20250727124459_7f339572",
      "description": "A test field created by VCR",
      "api_slug": "vcr_test_field_test_20250727124459_7f339572",
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
      "created_at": "2025-07-27T12:45:00.103000000Z",
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
        "attribute_id": "94ff6c5b-4bbe-4c60-8be3-f542250e3417"
      },
      "title": "VCR Test Field test_20250727124805_5aaef00f",
      "description": "A test field created by VCR",
      "api_slug": "vcr_test_field_test_20250727124805_5aaef00f",
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
      "created_at": "2025-07-27T12:48:05.513000000Z",
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
        "attribute_id": "4eb418c9-704c-40be-8712-3d99cc0add8d"
      },
      "title": "VCR Test Field test_20250727125153_ff5b97ae",
      "description": "A test field created by VCR",
      "api_slug": "vcr_test_field_test_20250727125153_ff5b97ae",
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
      "created_at": "2025-07-27T12:51:54.302000000Z",
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
        "attribute_id": "0a7f562b-b055-408a-9824-3ace256f35ed"
      },
      "title": "VCR Test Field test_20250727091627_c7e6700b",
      "description": "A test field created by VCR",
      "api_slug": "vcr_test_field_test_20250727091627_c7e6700b",
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
      "created_at": "2025-07-27T13:16:28.382000000Z",
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
        "attribute_id": "afe679a0-4774-4660-88ea-e8699014b242"
      },
      "title": "VCR Test Field test_20250727091736_41a0e5e1",
      "description": "A test field created by VCR",
      "api_slug": "vcr_test_field_test_20250727091736_41a0e5e1",
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
      "created_at": "2025-07-27T13:17:37.085000000Z",
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
        "attribute_id": "286e5f2b-60ae-4ec7-b3c5-1ca6b9028820"
      },
      "title": "VCR Test Field test_20250727131819_875a7762",
      "description": "A test field created by VCR",
      "api_slug": "vcr_test_field_test_20250727131819_875a7762",
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
      "created_at": "2025-07-27T13:18:19.535000000Z",
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
        "attribute_id": "a0f6ef86-6f1d-4825-8ad7-4a01bf2fac61"
      },
      "title": "VCR Test Field test_20250727092333_9bcf7098",
      "description": "A test field created by VCR",
      "api_slug": "vcr_test_field_test_20250727092333_9bcf7098",
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
      "created_at": "2025-07-27T13:23:33.897000000Z",
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
        "attribute_id": "85473bc7-3949-4f8a-a7e8-4b157693bb5e"
      },
      "title": "VCR Test Field test_20250727092918_301715e4",
      "description": "A test field created by VCR",
      "api_slug": "vcr_test_field_test_20250727092918_301715e4",
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
      "created_at": "2025-07-27T13:29:18.678000000Z",
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
        "attribute_id": "4e3f4328-506a-4e5e-8a33-2eafd886557a"
      },
      "title": "VCR Test Field test_20250727093554_602e9979",
      "description": "A test field created by VCR",
      "api_slug": "vcr_test_field_test_20250727093554_602e9979",
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
      "created_at": "2025-07-27T13:35:54.845000000Z",
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
        "attribute_id": "6ec338f9-06ae-4951-b38b-72f53fda7cbe"
      },
      "title": "VCR Test Field test_20250727093644_1a479b31",
      "description": "A test field created by VCR",
      "api_slug": "vcr_test_field_test_20250727093644_1a479b31",
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
      "created_at": "2025-07-27T13:36:45.369000000Z",
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
        "attribute_id": "33339acf-fa45-4708-adea-939a2f6b2a93"
      },
      "title": "VCR Test Field test_20250727093854_e93484cf",
      "description": "A test field created by VCR",
      "api_slug": "vcr_test_field_test_20250727093854_e93484cf",
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
      "created_at": "2025-07-27T13:38:54.533000000Z",
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
        "attribute_id": "a25e9885-fc13-4abc-a008-d5d073b0c184"
      },
      "title": "VCR Test Field test_20250727093940_ab528ad2",
      "description": "A test field created by VCR",
      "api_slug": "vcr_test_field_test_20250727093940_ab528ad2",
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
      "created_at": "2025-07-27T13:39:40.499000000Z",
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

### Create
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

### Retrieve
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

### Update
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

### Archive
`POST /v2/attributes/{attribute_id}/archive`

```json
{
  "error": "Attio::NotFoundError",
  "message": "Resource not found",
  "response_body": {
    "status": 404,
    "headers": {
      "date": "Sun, 27 Jul 2025 14:06:21 GMT",
      "content-type": "application/json; charset=utf-8",
      "transfer-encoding": "chunked",
      "connection": "keep-alive",
      "content-encoding": "gzip",
      "x-attio-execution-id": "465d2ec9-f0c9-4f34-b576-8874408bbb92",
      "vary": "Origin",
      "access-control-allow-origin": "*",
      "access-control-expose-headers": "x-attio-client,x-attio-execution-id,x-attio-platform,x-attio-platform-version,x-attio-record-query-score,x-attio-app-installation-bundle-id",
      "x-frame-options": "DENY",
      "via": "1.1 google",
      "cf-cache-status": "DYNAMIC",
      "strict-transport-security": "max-age=7776000; includeSubDomains; preload",
      "server": "cloudflare",
      "cf-ray": "965cb26a6f130f65-EWR"
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

### Unarchive
`POST /v2/attributes/{attribute_id}/unarchive`

```json
{
  "error": "Attio::NotFoundError",
  "message": "Resource not found",
  "response_body": {
    "status": 404,
    "headers": {
      "date": "Sun, 27 Jul 2025 14:06:22 GMT",
      "content-type": "application/json; charset=utf-8",
      "transfer-encoding": "chunked",
      "connection": "keep-alive",
      "content-encoding": "gzip",
      "x-attio-execution-id": "76a927a5-ccef-42eb-b23e-adc88dd0bfb3",
      "vary": "Origin",
      "access-control-allow-origin": "*",
      "access-control-expose-headers": "x-attio-client,x-attio-execution-id,x-attio-platform,x-attio-platform-version,x-attio-record-query-score,x-attio-app-installation-bundle-id",
      "x-frame-options": "DENY",
      "via": "1.1 google",
      "cf-cache-status": "DYNAMIC",
      "strict-transport-security": "max-age=7776000; includeSubDomains; preload",
      "server": "cloudflare",
      "cf-ray": "965cb26bcf98de96-EWR"
    },
    "body": {
      "status_code": 404,
      "type": "invalid_request_error",
      "code": "not_found",
      "message": "Could not find endpoint \"POST /v2/attributes/10ea9ef1-6857-4af1-834e-a5c8864afc12/unarchive\"."
    }
  }
}
```

## Lists

### List
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
      "parent_object": [
        "companies"
      ],
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
      "parent_object": [
        "people"
      ],
      "created_by_actor": {
        "type": "api-token",
        "id": "4c9b8eb9-4b5d-4b27-a37c-6a9ff08bd3ee"
      }
    },
    {
      "id": {
        "workspace_id": "a96c9c20-442b-43cd-a94b-3d4683051661",
        "list_id": "d545b0fe-4568-4775-8126-80f8baf7f91f"
      },
      "api_slug": "test_sdk_list_1753578970",
      "created_at": "2025-07-27T01:16:10.863000000Z",
      "name": "Test SDK List 1753578970",
      "workspace_access": "full-access",
      "workspace_member_access": [],
      "parent_object": [
        "people"
      ],
      "created_by_actor": {
        "type": "api-token",
        "id": "4c9b8eb9-4b5d-4b27-a37c-6a9ff08bd3ee"
      }
    },
    {
      "id": {
        "workspace_id": "a96c9c20-442b-43cd-a94b-3d4683051661",
        "list_id": "173ff5dd-18af-4108-af8d-4deded8f0401"
      },
      "api_slug": "test_sdk_list_1753579025",
      "created_at": "2025-07-27T01:17:05.553000000Z",
      "name": "Test SDK List 1753579025",
      "workspace_access": "full-access",
      "workspace_member_access": [],
      "parent_object": [
        "people"
      ],
      "created_by_actor": {
        "type": "api-token",
        "id": "4c9b8eb9-4b5d-4b27-a37c-6a9ff08bd3ee"
      }
    },
    {
      "id": {
        "workspace_id": "a96c9c20-442b-43cd-a94b-3d4683051661",
        "list_id": "1dde9865-9161-4b4c-8ec7-82512a2cecfe"
      },
      "api_slug": "test_sdk_list_1753579035",
      "created_at": "2025-07-27T01:17:15.553000000Z",
      "name": "Test SDK List 1753579035",
      "workspace_access": "full-access",
      "workspace_member_access": [],
      "parent_object": [
        "people"
      ],
      "created_by_actor": {
        "type": "api-token",
        "id": "4c9b8eb9-4b5d-4b27-a37c-6a9ff08bd3ee"
      }
    },
    {
      "id": {
        "workspace_id": "a96c9c20-442b-43cd-a94b-3d4683051661",
        "list_id": "6118d151-c1b2-4bfb-9f69-cd6a573a1ae0"
      },
      "api_slug": "test_sdk_list_1753579054",
      "created_at": "2025-07-27T01:17:35.185000000Z",
      "name": "Updated Test List Name",
      "workspace_access": "full-access",
      "workspace_member_access": [],
      "parent_object": [
        "people"
      ],
      "created_by_actor": {
        "type": "api-token",
        "id": "4c9b8eb9-4b5d-4b27-a37c-6a9ff08bd3ee"
      }
    },
    {
      "id": {
        "workspace_id": "a96c9c20-442b-43cd-a94b-3d4683051661",
        "list_id": "784ff8b3-bf62-4aca-8466-ceb1ee19399d"
      },
      "api_slug": "test_sdk_list_1753579065",
      "created_at": "2025-07-27T01:17:45.750000000Z",
      "name": "Test SDK List 1753579065",
      "workspace_access": "full-access",
      "workspace_member_access": [],
      "parent_object": [
        "people"
      ],
      "created_by_actor": {
        "type": "api-token",
        "id": "4c9b8eb9-4b5d-4b27-a37c-6a9ff08bd3ee"
      }
    },
    {
      "id": {
        "workspace_id": "a96c9c20-442b-43cd-a94b-3d4683051661",
        "list_id": "ab5caa8c-bc06-41ef-a58e-3d1c9e9bdd9e"
      },
      "api_slug": "test_sdk_list_1753579107",
      "created_at": "2025-07-27T01:18:27.427000000Z",
      "name": "Test SDK List 1753579107",
      "workspace_access": "full-access",
      "workspace_member_access": [],
      "parent_object": [
        "people"
      ],
      "created_by_actor": {
        "type": "api-token",
        "id": "4c9b8eb9-4b5d-4b27-a37c-6a9ff08bd3ee"
      }
    },
    {
      "id": {
        "workspace_id": "a96c9c20-442b-43cd-a94b-3d4683051661",
        "list_id": "130fcb20-b39f-4e69-8b3a-704a3c54e8d1"
      },
      "api_slug": "test_sdk_list_1753579136",
      "created_at": "2025-07-27T01:18:56.774000000Z",
      "name": "Updated Test SDK List 1753579136",
      "workspace_access": "full-access",
      "workspace_member_access": [],
      "parent_object": [
        "people"
      ],
      "created_by_actor": {
        "type": "api-token",
        "id": "4c9b8eb9-4b5d-4b27-a37c-6a9ff08bd3ee"
      }
    },
    {
      "id": {
        "workspace_id": "a96c9c20-442b-43cd-a94b-3d4683051661",
        "list_id": "75a28e95-a6d8-4604-a46d-d7466d78d596"
      },
      "api_slug": "test_sdk_list_1753579249",
      "created_at": "2025-07-27T01:20:50.519000000Z",
      "name": "Updated Test SDK List 1753579249",
      "workspace_access": "full-access",
      "workspace_member_access": [],
      "parent_object": [
        "people"
      ],
      "created_by_actor": {
        "type": "api-token",
        "id": "4c9b8eb9-4b5d-4b27-a37c-6a9ff08bd3ee"
      }
    },
    {
      "id": {
        "workspace_id": "a96c9c20-442b-43cd-a94b-3d4683051661",
        "list_id": "518c1375-1700-4a75-80e8-8c873174283c"
      },
      "api_slug": "vcr_test_list",
      "created_at": "2025-07-27T01:46:59.779000000Z",
      "name": "VCR Test List",
      "workspace_access": "full-access",
      "workspace_member_access": [],
      "parent_object": [
        "people"
      ],
      "created_by_actor": {
        "type": "api-token",
        "id": "4c9b8eb9-4b5d-4b27-a37c-6a9ff08bd3ee"
      }
    },
    {
      "id": {
        "workspace_id": "a96c9c20-442b-43cd-a94b-3d4683051661",
        "list_id": "fa542089-565f-407e-847d-96a8a0592d67"
      },
      "api_slug": "vcr_test_list_test_20250727072457_dfbc38fb",
      "created_at": "2025-07-27T11:24:57.302000000Z",
      "name": "VCR Test List test_20250727072457_dfbc38fb",
      "workspace_access": "full-access",
      "workspace_member_access": [],
      "parent_object": [
        "people"
      ],
      "created_by_actor": {
        "type": "api-token",
        "id": "4c9b8eb9-4b5d-4b27-a37c-6a9ff08bd3ee"
      }
    },
    {
      "id": {
        "workspace_id": "a96c9c20-442b-43cd-a94b-3d4683051661",
        "list_id": "b96a3591-8424-4e25-a4cc-e4bb4d12bf67"
      },
      "api_slug": "vcr_test_list_test_20250727072508_457fa459",
      "created_at": "2025-07-27T11:25:08.695000000Z",
      "name": "VCR Test List test_20250727072508_457fa459",
      "workspace_access": "full-access",
      "workspace_member_access": [],
      "parent_object": [
        "people"
      ],
      "created_by_actor": {
        "type": "api-token",
        "id": "4c9b8eb9-4b5d-4b27-a37c-6a9ff08bd3ee"
      }
    },
    {
      "id": {
        "workspace_id": "a96c9c20-442b-43cd-a94b-3d4683051661",
        "list_id": "59712848-6397-473e-b1a4-e7c0a3738356"
      },
      "api_slug": "vcr_test_list_test_20250727113156_f1ad8092",
      "created_at": "2025-07-27T11:31:56.723000000Z",
      "name": "VCR Test List test_20250727113156_f1ad8092",
      "workspace_access": "full-access",
      "workspace_member_access": [],
      "parent_object": [
        "people"
      ],
      "created_by_actor": {
        "type": "api-token",
        "id": "4c9b8eb9-4b5d-4b27-a37c-6a9ff08bd3ee"
      }
    },
    {
      "id": {
        "workspace_id": "a96c9c20-442b-43cd-a94b-3d4683051661",
        "list_id": "ef043efb-9a74-4e26-a183-775a0549b88b"
      },
      "api_slug": "vcr_test_list_test_20250727114339_17717947",
      "created_at": "2025-07-27T11:43:39.542000000Z",
      "name": "VCR Test List test_20250727114339_17717947",
      "workspace_access": "full-access",
      "workspace_member_access": [],
      "parent_object": [
        "people"
      ],
      "created_by_actor": {
        "type": "api-token",
        "id": "4c9b8eb9-4b5d-4b27-a37c-6a9ff08bd3ee"
      }
    },
    {
      "id": {
        "workspace_id": "a96c9c20-442b-43cd-a94b-3d4683051661",
        "list_id": "d7b66529-b722-494c-8792-6db0e98134c0"
      },
      "api_slug": "vcr_test_list_test_20250727122355_c9034f73",
      "created_at": "2025-07-27T12:23:55.323000000Z",
      "name": "VCR Test List test_20250727122355_c9034f73",
      "workspace_access": "full-access",
      "workspace_member_access": [],
      "parent_object": [
        "people"
      ],
      "created_by_actor": {
        "type": "api-token",
        "id": "4c9b8eb9-4b5d-4b27-a37c-6a9ff08bd3ee"
      }
    },
    {
      "id": {
        "workspace_id": "a96c9c20-442b-43cd-a94b-3d4683051661",
        "list_id": "ff4f3909-ac2a-4c02-8b2b-c26d882feb8c"
      },
      "api_slug": "vcr_test_list_test_20250727122700_6b9acb6d",
      "created_at": "2025-07-27T12:27:01.200000000Z",
      "name": "VCR Test List test_20250727122700_6b9acb6d",
      "workspace_access": "full-access",
      "workspace_member_access": [],
      "parent_object": [
        "people"
      ],
      "created_by_actor": {
        "type": "api-token",
        "id": "4c9b8eb9-4b5d-4b27-a37c-6a9ff08bd3ee"
      }
    },
    {
      "id": {
        "workspace_id": "a96c9c20-442b-43cd-a94b-3d4683051661",
        "list_id": "64feace7-86b3-4ea1-be35-2eed8f7a0adf"
      },
      "api_slug": "vcr_test_list_test_20250727124125_f49d0e6c",
      "created_at": "2025-07-27T12:41:25.523000000Z",
      "name": "VCR Test List test_20250727124125_f49d0e6c",
      "workspace_access": "full-access",
      "workspace_member_access": [],
      "parent_object": [
        "people"
      ],
      "created_by_actor": {
        "type": "api-token",
        "id": "4c9b8eb9-4b5d-4b27-a37c-6a9ff08bd3ee"
      }
    },
    {
      "id": {
        "workspace_id": "a96c9c20-442b-43cd-a94b-3d4683051661",
        "list_id": "a008d1f6-41f0-4072-aea9-6f637ee4ac63"
      },
      "api_slug": "vcr_test_list_test_20250727124501_5fde01de",
      "created_at": "2025-07-27T12:45:01.569000000Z",
      "name": "VCR Test List test_20250727124501_5fde01de",
      "workspace_access": "full-access",
      "workspace_member_access": [],
      "parent_object": [
        "people"
      ],
      "created_by_actor": {
        "type": "api-token",
        "id": "4c9b8eb9-4b5d-4b27-a37c-6a9ff08bd3ee"
      }
    },
    {
      "id": {
        "workspace_id": "a96c9c20-442b-43cd-a94b-3d4683051661",
        "list_id": "e2b38ef0-a766-44da-b409-9311d998c72c"
      },
      "api_slug": "vcr_test_list_test_20250727124802_9191a25a",
      "created_at": "2025-07-27T12:48:02.685000000Z",
      "name": "VCR Test List test_20250727124802_9191a25a",
      "workspace_access": "full-access",
      "workspace_member_access": [],
      "parent_object": [
        "people"
      ],
      "created_by_actor": {
        "type": "api-token",
        "id": "4c9b8eb9-4b5d-4b27-a37c-6a9ff08bd3ee"
      }
    },
    {
      "id": {
        "workspace_id": "a96c9c20-442b-43cd-a94b-3d4683051661",
        "list_id": "ab806f97-508d-4979-83f4-0c1547e1547c"
      },
      "api_slug": "vcr_test_list_test_20250727125151_e61ecaf0",
      "created_at": "2025-07-27T12:51:51.967000000Z",
      "name": "VCR Test List test_20250727125151_e61ecaf0",
      "workspace_access": "full-access",
      "workspace_member_access": [],
      "parent_object": [
        "people"
      ],
      "created_by_actor": {
        "type": "api-token",
        "id": "4c9b8eb9-4b5d-4b27-a37c-6a9ff08bd3ee"
      }
    },
    {
      "id": {
        "workspace_id": "a96c9c20-442b-43cd-a94b-3d4683051661",
        "list_id": "97daef10-84a8-440f-b090-854a92e5f70a"
      },
      "api_slug": "vcr_test_list_test_20250727091628_6b56ef2c",
      "created_at": "2025-07-27T13:16:28.826000000Z",
      "name": "VCR Test List test_20250727091628_6b56ef2c",
      "workspace_access": "full-access",
      "workspace_member_access": [],
      "parent_object": [
        "people"
      ],
      "created_by_actor": {
        "type": "api-token",
        "id": "4c9b8eb9-4b5d-4b27-a37c-6a9ff08bd3ee"
      }
    },
    {
      "id": {
        "workspace_id": "a96c9c20-442b-43cd-a94b-3d4683051661",
        "list_id": "b010ea4b-270f-4d82-a36f-4e6f9b5df80b"
      },
      "api_slug": "vcr_test_list_test_20250727091736_c18bccfd",
      "created_at": "2025-07-27T13:17:36.593000000Z",
      "name": "VCR Test List test_20250727091736_c18bccfd",
      "workspace_access": "full-access",
      "workspace_member_access": [],
      "parent_object": [
        "people"
      ],
      "created_by_actor": {
        "type": "api-token",
        "id": "4c9b8eb9-4b5d-4b27-a37c-6a9ff08bd3ee"
      }
    },
    {
      "id": {
        "workspace_id": "a96c9c20-442b-43cd-a94b-3d4683051661",
        "list_id": "81378acb-f401-4e43-9c7d-6de93b06e944"
      },
      "api_slug": "vcr_test_list_test_20250727131820_e57271ba",
      "created_at": "2025-07-27T13:18:20.578000000Z",
      "name": "VCR Test List test_20250727131820_e57271ba",
      "workspace_access": "full-access",
      "workspace_member_access": [],
      "parent_object": [
        "people"
      ],
      "created_by_actor": {
        "type": "api-token",
        "id": "4c9b8eb9-4b5d-4b27-a37c-6a9ff08bd3ee"
      }
    },
    {
      "id": {
        "workspace_id": "a96c9c20-442b-43cd-a94b-3d4683051661",
        "list_id": "1467254d-c90d-4632-b1a8-7bcdd0dc7b8f"
      },
      "api_slug": "vcr_test_list_test_20250727092333_0f386cb9",
      "created_at": "2025-07-27T13:23:33.416000000Z",
      "name": "VCR Test List test_20250727092333_0f386cb9",
      "workspace_access": "full-access",
      "workspace_member_access": [],
      "parent_object": [
        "people"
      ],
      "created_by_actor": {
        "type": "api-token",
        "id": "4c9b8eb9-4b5d-4b27-a37c-6a9ff08bd3ee"
      }
    },
    {
      "id": {
        "workspace_id": "a96c9c20-442b-43cd-a94b-3d4683051661",
        "list_id": "9b585d9e-1413-4d4c-b2fd-103dcd1d690a"
      },
      "api_slug": "vcr_test_list_test_20250727092918_b1e1a979",
      "created_at": "2025-07-27T13:29:19.100000000Z",
      "name": "VCR Test List test_20250727092918_b1e1a979",
      "workspace_access": "full-access",
      "workspace_member_access": [],
      "parent_object": [
        "people"
      ],
      "created_by_actor": {
        "type": "api-token",
        "id": "4c9b8eb9-4b5d-4b27-a37c-6a9ff08bd3ee"
      }
    },
    {
      "id": {
        "workspace_id": "a96c9c20-442b-43cd-a94b-3d4683051661",
        "list_id": "efcba0df-2d5e-43de-87e5-d7ee632766b9"
      },
      "api_slug": "vcr_test_list_test_20250727093554_ca67fdc3",
      "created_at": "2025-07-27T13:35:55.296000000Z",
      "name": "VCR Test List test_20250727093554_ca67fdc3",
      "workspace_access": "full-access",
      "workspace_member_access": [],
      "parent_object": [
        "people"
      ],
      "created_by_actor": {
        "type": "api-token",
        "id": "4c9b8eb9-4b5d-4b27-a37c-6a9ff08bd3ee"
      }
    },
    {
      "id": {
        "workspace_id": "a96c9c20-442b-43cd-a94b-3d4683051661",
        "list_id": "73eeabb0-84a6-408c-8628-68f7f61cbba9"
      },
      "api_slug": "vcr_test_list_test_20250727093645_c813fd1d",
      "created_at": "2025-07-27T13:36:45.895000000Z",
      "name": "VCR Test List test_20250727093645_c813fd1d",
      "workspace_access": "full-access",
      "workspace_member_access": [],
      "parent_object": [
        "people"
      ],
      "created_by_actor": {
        "type": "api-token",
        "id": "4c9b8eb9-4b5d-4b27-a37c-6a9ff08bd3ee"
      }
    },
    {
      "id": {
        "workspace_id": "a96c9c20-442b-43cd-a94b-3d4683051661",
        "list_id": "12b55964-5def-4f28-a091-d77707e2363b"
      },
      "api_slug": "vcr_test_list_test_20250727093854_0caf2aec",
      "created_at": "2025-07-27T13:38:54.954000000Z",
      "name": "VCR Test List test_20250727093854_0caf2aec",
      "workspace_access": "full-access",
      "workspace_member_access": [],
      "parent_object": [
        "people"
      ],
      "created_by_actor": {
        "type": "api-token",
        "id": "4c9b8eb9-4b5d-4b27-a37c-6a9ff08bd3ee"
      }
    },
    {
      "id": {
        "workspace_id": "a96c9c20-442b-43cd-a94b-3d4683051661",
        "list_id": "8b9198c5-4d9f-41ba-b9f9-a891b26754e9"
      },
      "api_slug": "vcr_test_list_test_20250727093940_a4ecc153",
      "created_at": "2025-07-27T13:39:40.999000000Z",
      "name": "VCR Test List test_20250727093940_a4ecc153",
      "workspace_access": "full-access",
      "workspace_member_access": [],
      "parent_object": [
        "people"
      ],
      "created_by_actor": {
        "type": "api-token",
        "id": "4c9b8eb9-4b5d-4b27-a37c-6a9ff08bd3ee"
      }
    }
  ]
}
```

### Create
`POST /v2/lists`

```json
{
  "error": "Attio::BadRequestError",
  "message": "Bad request",
  "response_body": {
    "status": 400,
    "headers": {
      "date": "Sun, 27 Jul 2025 14:06:22 GMT",
      "content-type": "application/json; charset=utf-8",
      "content-length": "547",
      "connection": "keep-alive",
      "cf-ray": "965cb26e6a243d85-EWR",
      "x-attio-execution-id": "d4870f7b-433c-43d1-ad13-b3b4e42650b1",
      "vary": "Origin",
      "access-control-allow-origin": "*",
      "access-control-expose-headers": "x-attio-client,x-attio-execution-id,x-attio-platform,x-attio-platform-version,x-attio-record-query-score,x-attio-app-installation-bundle-id",
      "x-frame-options": "DENY",
      "via": "1.1 google",
      "cf-cache-status": "DYNAMIC",
      "strict-transport-security": "max-age=7776000; includeSubDomains; preload",
      "server": "cloudflare"
    },
    "body": {
      "status_code": 400,
      "type": "invalid_request_error",
      "code": "validation_type",
      "message": "Body payload validation error.",
      "validation_errors": [
        {
          "code": "invalid_type",
          "path": [
            "data",
            "api_slug"
          ],
          "message": "Required",
          "expected": "string",
          "received": "undefined"
        },
        {
          "code": "invalid_type",
          "path": [
            "data",
            "workspace_access"
          ],
          "message": "Required",
          "expected": "'full-access' | 'read-and-write' | 'read-only'",
          "received": "undefined"
        },
        {
          "code": "invalid_type",
          "path": [
            "data",
            "workspace_member_access"
          ],
          "message": "Required",
          "expected": "array",
          "received": "undefined"
        }
      ]
    }
  }
}
```

## Records

### List Companies
`GET /v2/objects/companies/records`

```json
{
  "error": "Attio::NotFoundError",
  "message": "Resource not found",
  "response_body": {
    "status": 404,
    "headers": {
      "date": "Sun, 27 Jul 2025 14:06:22 GMT",
      "content-type": "application/json; charset=utf-8",
      "transfer-encoding": "chunked",
      "connection": "keep-alive",
      "content-encoding": "gzip",
      "x-attio-execution-id": "8ebe4a5e-a316-471e-8ce4-5613ec18da29",
      "vary": "Origin",
      "access-control-allow-origin": "*",
      "access-control-expose-headers": "x-attio-client,x-attio-execution-id,x-attio-platform,x-attio-platform-version,x-attio-record-query-score,x-attio-app-installation-bundle-id",
      "x-frame-options": "DENY",
      "via": "1.1 google",
      "cf-cache-status": "DYNAMIC",
      "strict-transport-security": "max-age=7776000; includeSubDomains; preload",
      "server": "cloudflare",
      "cf-ray": "965cb26fcae66e28-EWR"
    },
    "body": {
      "status_code": 404,
      "type": "invalid_request_error",
      "code": "not_found",
      "message": "Could not find endpoint \"GET /v2/objects/companies/records\"."
    }
  }
}
```

### List People
`GET /v2/objects/people/records`

```json
{
  "error": "Attio::NotFoundError",
  "message": "Resource not found",
  "response_body": {
    "status": 404,
    "headers": {
      "date": "Sun, 27 Jul 2025 14:06:23 GMT",
      "content-type": "application/json; charset=utf-8",
      "transfer-encoding": "chunked",
      "connection": "keep-alive",
      "content-encoding": "gzip",
      "x-attio-execution-id": "6f271867-07a1-42e4-a5c3-9b6be0124a08",
      "vary": "Origin",
      "access-control-allow-origin": "*",
      "access-control-expose-headers": "x-attio-client,x-attio-execution-id,x-attio-platform,x-attio-platform-version,x-attio-record-query-score,x-attio-app-installation-bundle-id",
      "x-frame-options": "DENY",
      "via": "1.1 google",
      "cf-cache-status": "DYNAMIC",
      "strict-transport-security": "max-age=7776000; includeSubDomains; preload",
      "server": "cloudflare",
      "cf-ray": "965cb2710c930f5d-EWR"
    },
    "body": {
      "status_code": 404,
      "type": "invalid_request_error",
      "code": "not_found",
      "message": "Could not find endpoint \"GET /v2/objects/people/records\"."
    }
  }
}
```

### Create
`POST /v2/objects/{object}/records`

```json
{
  "error": "Attio::BadRequestError",
  "message": "Bad request",
  "response_body": {
    "status": 400,
    "headers": {
      "date": "Sun, 27 Jul 2025 14:06:23 GMT",
      "content-type": "application/json; charset=utf-8",
      "content-length": "498",
      "connection": "keep-alive",
      "cf-ray": "965cb27298561aea-EWR",
      "x-attio-execution-id": "332e52b4-97f2-411a-92a8-09d369b8cf58",
      "vary": "Origin",
      "access-control-allow-origin": "*",
      "access-control-expose-headers": "x-attio-client,x-attio-execution-id,x-attio-platform,x-attio-platform-version,x-attio-record-query-score,x-attio-app-installation-bundle-id",
      "x-frame-options": "DENY",
      "via": "1.1 google",
      "cf-cache-status": "DYNAMIC",
      "strict-transport-security": "max-age=7776000; includeSubDomains; preload",
      "server": "cloudflare"
    },
    "body": {
      "status_code": 400,
      "type": "invalid_request_error",
      "code": "validation_type",
      "message": "An invalid value was passed to attribute with slug \"name\".",
      "validation_errors": [
        {
          "code": "invalid_type",
          "path": [
            "first_name"
          ],
          "message": "Required",
          "expected": "string",
          "received": "undefined"
        },
        {
          "code": "invalid_type",
          "path": [
            "last_name"
          ],
          "message": "Required",
          "expected": "string",
          "received": "undefined"
        },
        {
          "code": "invalid_type",
          "path": [
            "full_name"
          ],
          "message": "Required",
          "expected": "string",
          "received": "undefined"
        }
      ]
    }
  }
}
```

## Webhooks

### List
`GET /v2/webhooks`

```json
{
  "data": []
}
```

### Create
`POST /v2/webhooks`

```json
{
  "error": "Attio::BadRequestError",
  "message": "Bad request",
  "response_body": {
    "status": 400,
    "headers": {
      "date": "Sun, 27 Jul 2025 14:06:23 GMT",
      "content-type": "application/json; charset=utf-8",
      "content-length": "376",
      "connection": "keep-alive",
      "cf-ray": "965cb2773f9a7295-EWR",
      "x-attio-execution-id": "a7e75d7b-ee72-4ecc-b78a-ed3a2eb4171d",
      "vary": "Origin",
      "access-control-allow-origin": "*",
      "access-control-expose-headers": "x-attio-client,x-attio-execution-id,x-attio-platform,x-attio-platform-version,x-attio-record-query-score,x-attio-app-installation-bundle-id",
      "x-frame-options": "DENY",
      "via": "1.1 google",
      "cf-cache-status": "DYNAMIC",
      "strict-transport-security": "max-age=7776000; includeSubDomains; preload",
      "server": "cloudflare"
    },
    "body": {
      "status_code": 400,
      "type": "invalid_request_error",
      "code": "validation_type",
      "message": "Body payload validation error.",
      "validation_errors": [
        {
          "code": "invalid_type",
          "path": [
            "data",
            "target_url"
          ],
          "message": "Required",
          "expected": "string",
          "received": "undefined"
        },
        {
          "code": "invalid_type",
          "path": [
            "data",
            "subscriptions"
          ],
          "message": "Required",
          "expected": "array",
          "received": "undefined"
        }
      ]
    }
  }
}
```

## Workspace Members

### List
`GET /v2/workspace_members`

```json
{
  "data": [
    {
      "id": {
        "workspace_id": "a96c9c20-442b-43cd-a94b-3d4683051661",
        "workspace_member_id": "1757c0bb-f8e6-4013-b41d-2e49a3ef2c6f"
      },
      "first_name": "Robert",
      "last_name": "Beene",
      "avatar_url": "https://lh3.googleusercontent.com/a/ACg8ocL-ksS1-L-QHG4sFM9-DYrDYNym7CgBxqhiUDQYlEMQ5riPJA=s96-c",
      "email_address": "robert@ismly.com",
      "access_level": "admin",
      "created_at": "2025-07-18T13:49:47.914000000Z"
    }
  ]
}
```

### Retrieve
`GET /v2/workspace_members/{workspace_member_id}`

```json
{
  "data": {
    "id": {
      "workspace_id": "a96c9c20-442b-43cd-a94b-3d4683051661",
      "workspace_member_id": "1757c0bb-f8e6-4013-b41d-2e49a3ef2c6f"
    },
    "first_name": "Robert",
    "last_name": "Beene",
    "avatar_url": "https://lh3.googleusercontent.com/a/ACg8ocL-ksS1-L-QHG4sFM9-DYrDYNym7CgBxqhiUDQYlEMQ5riPJA=s96-c",
    "email_address": "robert@ismly.com",
    "access_level": "admin",
    "created_at": "2025-07-18T13:49:47.914000000Z"
  }
}
```

## Notes

### List
`GET /v2/notes`

```json
{
  "data": [
    {
      "id": {
        "workspace_id": "a96c9c20-442b-43cd-a94b-3d4683051661",
        "note_id": "71fceca4-d4b3-43ee-bdab-b18250c87655"
      },
      "parent_object": "people",
      "parent_record_id": "3d461cb0-10ba-45bc-a5f3-e98b456ffffd",
      "title": "API Test Note",
      "content_plaintext": "Test note created at 2025-07-19 10:42:28.181027",
      "content_markdown": "Test note created at 2025-07-19 10:42:28.181027",
      "tags": [],
      "created_by_actor": {
        "type": "api-token",
        "id": "4c9b8eb9-4b5d-4b27-a37c-6a9ff08bd3ee"
      },
      "created_at": "2025-07-19T14:42:28.493000000Z"
    },
    {
      "id": {
        "workspace_id": "a96c9c20-442b-43cd-a94b-3d4683051661",
        "note_id": "59d5eac5-41df-4931-a542-579f4d1cac4d"
      },
      "parent_object": "people",
      "parent_record_id": "3d461cb0-10ba-45bc-a5f3-e98b456ffffd",
      "title": "API Test Note",
      "content_plaintext": "Test note created at 2025-07-19 11:03:24.371188",
      "content_markdown": "Test note created at 2025-07-19 11:03:24.371188",
      "tags": [],
      "created_by_actor": {
        "type": "api-token",
        "id": "4c9b8eb9-4b5d-4b27-a37c-6a9ff08bd3ee"
      },
      "created_at": "2025-07-19T15:03:24.669000000Z"
    },
    {
      "id": {
        "workspace_id": "a96c9c20-442b-43cd-a94b-3d4683051661",
        "note_id": "fa4c0dff-f32d-4457-a6b3-3a58e72ca012"
      },
      "parent_object": "people",
      "parent_record_id": "a796e27b-b21b-45f2-b3de-7358937026b9",
      "title": "First Contact",
      "content_plaintext": "Initial contact made at conference. Very interested in our solution.",
      "content_markdown": "Initial contact made at conference. Very interested in our solution.",
      "tags": [],
      "created_by_actor": {
        "type": "api-token",
        "id": "4c9b8eb9-4b5d-4b27-a37c-6a9ff08bd3ee"
      },
      "created_at": "2025-07-21T19:37:31.985000000Z"
    },
    {
      "id": {
        "workspace_id": "a96c9c20-442b-43cd-a94b-3d4683051661",
        "note_id": "7e22b58b-b742-426a-931d-0f6f2db0c2e2"
      },
      "parent_object": "deals",
      "parent_record_id": "e42c518c-5506-4eb1-891e-5f7cf4dc9154",
      "title": "Competitive Analysis",
      "content_plaintext": "Customer is comparing us with 2 competitors. Price is a key factor.",
      "content_markdown": "Customer is comparing us with 2 competitors. Price is a key factor.",
      "tags": [],
      "created_by_actor": {
        "type": "api-token",
        "id": "4c9b8eb9-4b5d-4b27-a37c-6a9ff08bd3ee"
      },
      "created_at": "2025-07-21T19:37:32.389000000Z"
    },
    {
      "id": {
        "workspace_id": "a96c9c20-442b-43cd-a94b-3d4683051661",
        "note_id": "a09e7200-4727-4392-9b60-1cfe1ce4baff"
      },
      "parent_object": "people",
      "parent_record_id": "df238345-c7a7-407b-a98e-5e9391d5afa7",
      "title": "Test Note",
      "content_plaintext": "This is a test note for a person",
      "content_markdown": "This is a test note for a person",
      "tags": [],
      "created_by_actor": {
        "type": "api-token",
        "id": "4c9b8eb9-4b5d-4b27-a37c-6a9ff08bd3ee"
      },
      "created_at": "2025-07-21T19:37:54.259000000Z"
    },
    {
      "id": {
        "workspace_id": "a96c9c20-442b-43cd-a94b-3d4683051661",
        "note_id": "96f76857-4fcd-4300-b68a-bb5702a2e118"
      },
      "parent_object": "deals",
      "parent_record_id": "ce215c2b-656f-4554-9ed3-7a4fbc027bfa",
      "title": "Progress Update",
      "content_plaintext": "Deal progress note",
      "content_markdown": "Deal progress note",
      "tags": [],
      "created_by_actor": {
        "type": "api-token",
        "id": "4c9b8eb9-4b5d-4b27-a37c-6a9ff08bd3ee"
      },
      "created_at": "2025-07-21T19:37:56.197000000Z"
    },
    {
      "id": {
        "workspace_id": "a96c9c20-442b-43cd-a94b-3d4683051661",
        "note_id": "69485bb1-d4e1-46db-9132-0586e795cb61"
      },
      "parent_object": "people",
      "parent_record_id": "09d57386-ab6f-4f2d-947c-26cebe3bc8d5",
      "title": "Get Test",
      "content_plaintext": "Test get note",
      "content_markdown": "Test get note",
      "tags": [],
      "created_by_actor": {
        "type": "api-token",
        "id": "4c9b8eb9-4b5d-4b27-a37c-6a9ff08bd3ee"
      },
      "created_at": "2025-07-21T19:37:58.394000000Z"
    },
    {
      "id": {
        "workspace_id": "a96c9c20-442b-43cd-a94b-3d4683051661",
        "note_id": "dfced26a-e3d2-4aaa-94f8-94a14b464fc0"
      },
      "parent_object": "people",
      "parent_record_id": "efd6fd31-7c70-45cc-beb6-6259c5ac72d3",
      "title": "Search Test",
      "content_plaintext": "UniqueNoteContent1753126678",
      "content_markdown": "UniqueNoteContent1753126678",
      "tags": [],
      "created_by_actor": {
        "type": "api-token",
        "id": "4c9b8eb9-4b5d-4b27-a37c-6a9ff08bd3ee"
      },
      "created_at": "2025-07-21T19:37:59.842000000Z"
    },
    {
      "id": {
        "workspace_id": "a96c9c20-442b-43cd-a94b-3d4683051661",
        "note_id": "0ed3dea6-3081-42dd-9c62-f1bdd1ebc3d8"
      },
      "parent_object": "deals",
      "parent_record_id": "ebc36475-0701-4dc3-8914-4b70445b2aa9",
      "title": "Progress Update",
      "content_plaintext": "Deal progress note",
      "content_markdown": "Deal progress note",
      "tags": [],
      "created_by_actor": {
        "type": "api-token",
        "id": "4c9b8eb9-4b5d-4b27-a37c-6a9ff08bd3ee"
      },
      "created_at": "2025-07-21T19:44:09.239000000Z"
    },
    {
      "id": {
        "workspace_id": "a96c9c20-442b-43cd-a94b-3d4683051661",
        "note_id": "f5e519a8-0ce6-4939-ba94-ad0548ce9ce6"
      },
      "parent_object": "people",
      "parent_record_id": "32821853-3b67-4118-b876-4a5808b59773",
      "title": "First Contact",
      "content_plaintext": "Initial contact made at conference. Very interested in our solution.",
      "content_markdown": "Initial contact made at conference. Very interested in our solution.",
      "tags": [],
      "created_by_actor": {
        "type": "api-token",
        "id": "4c9b8eb9-4b5d-4b27-a37c-6a9ff08bd3ee"
      },
      "created_at": "2025-07-21T20:57:35.719000000Z"
    }
  ]
}
```

## Errors

### 404

```json
{
  "error": "Attio::NotFoundError",
  "message": "Resource not found",
  "response_body": {
    "status": 404,
    "headers": {
      "date": "Sun, 27 Jul 2025 14:06:25 GMT",
      "content-type": "application/json; charset=utf-8",
      "transfer-encoding": "chunked",
      "connection": "keep-alive",
      "content-encoding": "gzip",
      "x-attio-execution-id": "6efd6d02-9ba7-467a-bdc1-d1361327f446",
      "vary": "Origin",
      "access-control-allow-origin": "*",
      "access-control-expose-headers": "x-attio-client,x-attio-execution-id,x-attio-platform,x-attio-platform-version,x-attio-record-query-score,x-attio-app-installation-bundle-id",
      "x-frame-options": "DENY",
      "via": "1.1 google",
      "cf-cache-status": "DYNAMIC",
      "strict-transport-security": "max-age=7776000; includeSubDomains; preload",
      "server": "cloudflare",
      "cf-ray": "965cb27d99e1efa9-EWR"
    },
    "body": {
      "status_code": 404,
      "type": "invalid_request_error",
      "code": "not_found",
      "message": "Could not find endpoint \"GET /v2/attributes/non-existent-id\"."
    }
  }
}
```

### 422 Invalid Type

```json
{
  "error": "Attio::BadRequestError",
  "message": "Bad request",
  "response_body": {
    "status": 400,
    "headers": {
      "date": "Sun, 27 Jul 2025 14:06:25 GMT",
      "content-type": "application/json; charset=utf-8",
      "content-length": "1407",
      "connection": "keep-alive",
      "cf-ray": "965cb27eeddf4391-EWR",
      "x-attio-execution-id": "4eda0d98-e53c-444e-8b76-4636a71c1992",
      "vary": "Origin",
      "access-control-allow-origin": "*",
      "access-control-expose-headers": "x-attio-client,x-attio-execution-id,x-attio-platform,x-attio-platform-version,x-attio-record-query-score,x-attio-app-installation-bundle-id",
      "x-frame-options": "DENY",
      "via": "1.1 google",
      "cf-cache-status": "DYNAMIC",
      "strict-transport-security": "max-age=7776000; includeSubDomains; preload",
      "server": "cloudflare"
    },
    "body": {
      "status_code": 400,
      "type": "invalid_request_error",
      "code": "validation_type",
      "message": "Body payload validation error.",
      "validation_errors": [
        {
          "code": "invalid_type",
          "path": [
            "data",
            "description"
          ],
          "message": "Required",
          "expected": "string",
          "received": "undefined"
        },
        {
          "code": "invalid_type",
          "path": [
            "data",
            "api_slug"
          ],
          "message": "Required",
          "expected": "string",
          "received": "undefined"
        },
        {
          "code": "invalid_option",
          "path": [
            "data",
            "type"
          ],
          "message": "Invalid enum value. Expected 'text' | 'number' | 'checkbox' | 'currency' | 'date' | 'timestamp' | 'rating' | 'status' | 'select' | 'record-reference' | 'actor-reference' | 'location' | 'domain' | 'email-address' | 'phone-number' | 'interaction' | 'personal-name', received 'invalid_type'",
          "options": [
            "text",
            "number",
            "checkbox",
            "currency",
            "date",
            "timestamp",
            "rating",
            "status",
            "select",
            "record-reference",
            "actor-reference",
            "location",
            "domain",
            "email-address",
            "phone-number",
            "interaction",
            "personal-name"
          ]
        },
        {
          "code": "invalid_type",
          "path": [
            "data",
            "is_required"
          ],
          "message": "Required",
          "expected": "boolean",
          "received": "undefined"
        },
        {
          "code": "invalid_type",
          "path": [
            "data",
            "is_unique"
          ],
          "message": "Required",
          "expected": "boolean",
          "received": "undefined"
        },
        {
          "code": "invalid_type",
          "path": [
            "data",
            "is_multiselect"
          ],
          "message": "Required",
          "expected": "boolean",
          "received": "undefined"
        },
        {
          "code": "invalid_type",
          "path": [
            "data",
            "config"
          ],
          "message": "Required",
          "expected": "object",
          "received": "undefined"
        }
      ]
    }
  }
}
```

### 400 Missing Required

```json
{
  "error": "Attio::BadRequestError",
  "message": "Bad request",
  "response_body": {
    "status": 400,
    "headers": {
      "date": "Sun, 27 Jul 2025 14:06:25 GMT",
      "content-type": "application/json; charset=utf-8",
      "content-length": "253",
      "connection": "keep-alive",
      "cf-ray": "965cb2808e6cc436-EWR",
      "x-attio-execution-id": "7f711948-57a6-4c50-89f0-021e38238141",
      "vary": "Origin",
      "access-control-allow-origin": "*",
      "access-control-expose-headers": "x-attio-client,x-attio-execution-id,x-attio-platform,x-attio-platform-version,x-attio-record-query-score,x-attio-app-installation-bundle-id",
      "x-frame-options": "DENY",
      "via": "1.1 google",
      "cf-cache-status": "DYNAMIC",
      "strict-transport-security": "max-age=7776000; includeSubDomains; preload",
      "server": "cloudflare"
    },
    "body": {
      "status_code": 400,
      "type": "invalid_request_error",
      "code": "validation_type",
      "message": "Body payload validation error.",
      "validation_errors": [
        {
          "code": "invalid_type",
          "path": [
            "data",
            "values"
          ],
          "message": "Required",
          "expected": "object",
          "received": "undefined"
        }
      ]
    }
  }
}
```

### 401

```json
{
  "status_code": 401,
  "type": "auth_error",
  "code": "unauthorized",
  "message": "The API Key provided was invalid because it was the wrong length (API Keys should be 64 characters long). You might not have copied the entire API key from your Admin panel?"
}
```

## Pagination

### First Page

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
      "parent_object": [
        "companies"
      ],
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
      "parent_object": [
        "people"
      ],
      "created_by_actor": {
        "type": "api-token",
        "id": "4c9b8eb9-4b5d-4b27-a37c-6a9ff08bd3ee"
      }
    },
    {
      "id": {
        "workspace_id": "a96c9c20-442b-43cd-a94b-3d4683051661",
        "list_id": "d545b0fe-4568-4775-8126-80f8baf7f91f"
      },
      "api_slug": "test_sdk_list_1753578970",
      "created_at": "2025-07-27T01:16:10.863000000Z",
      "name": "Test SDK List 1753578970",
      "workspace_access": "full-access",
      "workspace_member_access": [],
      "parent_object": [
        "people"
      ],
      "created_by_actor": {
        "type": "api-token",
        "id": "4c9b8eb9-4b5d-4b27-a37c-6a9ff08bd3ee"
      }
    },
    {
      "id": {
        "workspace_id": "a96c9c20-442b-43cd-a94b-3d4683051661",
        "list_id": "173ff5dd-18af-4108-af8d-4deded8f0401"
      },
      "api_slug": "test_sdk_list_1753579025",
      "created_at": "2025-07-27T01:17:05.553000000Z",
      "name": "Test SDK List 1753579025",
      "workspace_access": "full-access",
      "workspace_member_access": [],
      "parent_object": [
        "people"
      ],
      "created_by_actor": {
        "type": "api-token",
        "id": "4c9b8eb9-4b5d-4b27-a37c-6a9ff08bd3ee"
      }
    },
    {
      "id": {
        "workspace_id": "a96c9c20-442b-43cd-a94b-3d4683051661",
        "list_id": "1dde9865-9161-4b4c-8ec7-82512a2cecfe"
      },
      "api_slug": "test_sdk_list_1753579035",
      "created_at": "2025-07-27T01:17:15.553000000Z",
      "name": "Test SDK List 1753579035",
      "workspace_access": "full-access",
      "workspace_member_access": [],
      "parent_object": [
        "people"
      ],
      "created_by_actor": {
        "type": "api-token",
        "id": "4c9b8eb9-4b5d-4b27-a37c-6a9ff08bd3ee"
      }
    },
    {
      "id": {
        "workspace_id": "a96c9c20-442b-43cd-a94b-3d4683051661",
        "list_id": "6118d151-c1b2-4bfb-9f69-cd6a573a1ae0"
      },
      "api_slug": "test_sdk_list_1753579054",
      "created_at": "2025-07-27T01:17:35.185000000Z",
      "name": "Updated Test List Name",
      "workspace_access": "full-access",
      "workspace_member_access": [],
      "parent_object": [
        "people"
      ],
      "created_by_actor": {
        "type": "api-token",
        "id": "4c9b8eb9-4b5d-4b27-a37c-6a9ff08bd3ee"
      }
    },
    {
      "id": {
        "workspace_id": "a96c9c20-442b-43cd-a94b-3d4683051661",
        "list_id": "784ff8b3-bf62-4aca-8466-ceb1ee19399d"
      },
      "api_slug": "test_sdk_list_1753579065",
      "created_at": "2025-07-27T01:17:45.750000000Z",
      "name": "Test SDK List 1753579065",
      "workspace_access": "full-access",
      "workspace_member_access": [],
      "parent_object": [
        "people"
      ],
      "created_by_actor": {
        "type": "api-token",
        "id": "4c9b8eb9-4b5d-4b27-a37c-6a9ff08bd3ee"
      }
    },
    {
      "id": {
        "workspace_id": "a96c9c20-442b-43cd-a94b-3d4683051661",
        "list_id": "ab5caa8c-bc06-41ef-a58e-3d1c9e9bdd9e"
      },
      "api_slug": "test_sdk_list_1753579107",
      "created_at": "2025-07-27T01:18:27.427000000Z",
      "name": "Test SDK List 1753579107",
      "workspace_access": "full-access",
      "workspace_member_access": [],
      "parent_object": [
        "people"
      ],
      "created_by_actor": {
        "type": "api-token",
        "id": "4c9b8eb9-4b5d-4b27-a37c-6a9ff08bd3ee"
      }
    },
    {
      "id": {
        "workspace_id": "a96c9c20-442b-43cd-a94b-3d4683051661",
        "list_id": "130fcb20-b39f-4e69-8b3a-704a3c54e8d1"
      },
      "api_slug": "test_sdk_list_1753579136",
      "created_at": "2025-07-27T01:18:56.774000000Z",
      "name": "Updated Test SDK List 1753579136",
      "workspace_access": "full-access",
      "workspace_member_access": [],
      "parent_object": [
        "people"
      ],
      "created_by_actor": {
        "type": "api-token",
        "id": "4c9b8eb9-4b5d-4b27-a37c-6a9ff08bd3ee"
      }
    },
    {
      "id": {
        "workspace_id": "a96c9c20-442b-43cd-a94b-3d4683051661",
        "list_id": "75a28e95-a6d8-4604-a46d-d7466d78d596"
      },
      "api_slug": "test_sdk_list_1753579249",
      "created_at": "2025-07-27T01:20:50.519000000Z",
      "name": "Updated Test SDK List 1753579249",
      "workspace_access": "full-access",
      "workspace_member_access": [],
      "parent_object": [
        "people"
      ],
      "created_by_actor": {
        "type": "api-token",
        "id": "4c9b8eb9-4b5d-4b27-a37c-6a9ff08bd3ee"
      }
    },
    {
      "id": {
        "workspace_id": "a96c9c20-442b-43cd-a94b-3d4683051661",
        "list_id": "518c1375-1700-4a75-80e8-8c873174283c"
      },
      "api_slug": "vcr_test_list",
      "created_at": "2025-07-27T01:46:59.779000000Z",
      "name": "VCR Test List",
      "workspace_access": "full-access",
      "workspace_member_access": [],
      "parent_object": [
        "people"
      ],
      "created_by_actor": {
        "type": "api-token",
        "id": "4c9b8eb9-4b5d-4b27-a37c-6a9ff08bd3ee"
      }
    },
    {
      "id": {
        "workspace_id": "a96c9c20-442b-43cd-a94b-3d4683051661",
        "list_id": "fa542089-565f-407e-847d-96a8a0592d67"
      },
      "api_slug": "vcr_test_list_test_20250727072457_dfbc38fb",
      "created_at": "2025-07-27T11:24:57.302000000Z",
      "name": "VCR Test List test_20250727072457_dfbc38fb",
      "workspace_access": "full-access",
      "workspace_member_access": [],
      "parent_object": [
        "people"
      ],
      "created_by_actor": {
        "type": "api-token",
        "id": "4c9b8eb9-4b5d-4b27-a37c-6a9ff08bd3ee"
      }
    },
    {
      "id": {
        "workspace_id": "a96c9c20-442b-43cd-a94b-3d4683051661",
        "list_id": "b96a3591-8424-4e25-a4cc-e4bb4d12bf67"
      },
      "api_slug": "vcr_test_list_test_20250727072508_457fa459",
      "created_at": "2025-07-27T11:25:08.695000000Z",
      "name": "VCR Test List test_20250727072508_457fa459",
      "workspace_access": "full-access",
      "workspace_member_access": [],
      "parent_object": [
        "people"
      ],
      "created_by_actor": {
        "type": "api-token",
        "id": "4c9b8eb9-4b5d-4b27-a37c-6a9ff08bd3ee"
      }
    },
    {
      "id": {
        "workspace_id": "a96c9c20-442b-43cd-a94b-3d4683051661",
        "list_id": "59712848-6397-473e-b1a4-e7c0a3738356"
      },
      "api_slug": "vcr_test_list_test_20250727113156_f1ad8092",
      "created_at": "2025-07-27T11:31:56.723000000Z",
      "name": "VCR Test List test_20250727113156_f1ad8092",
      "workspace_access": "full-access",
      "workspace_member_access": [],
      "parent_object": [
        "people"
      ],
      "created_by_actor": {
        "type": "api-token",
        "id": "4c9b8eb9-4b5d-4b27-a37c-6a9ff08bd3ee"
      }
    },
    {
      "id": {
        "workspace_id": "a96c9c20-442b-43cd-a94b-3d4683051661",
        "list_id": "ef043efb-9a74-4e26-a183-775a0549b88b"
      },
      "api_slug": "vcr_test_list_test_20250727114339_17717947",
      "created_at": "2025-07-27T11:43:39.542000000Z",
      "name": "VCR Test List test_20250727114339_17717947",
      "workspace_access": "full-access",
      "workspace_member_access": [],
      "parent_object": [
        "people"
      ],
      "created_by_actor": {
        "type": "api-token",
        "id": "4c9b8eb9-4b5d-4b27-a37c-6a9ff08bd3ee"
      }
    },
    {
      "id": {
        "workspace_id": "a96c9c20-442b-43cd-a94b-3d4683051661",
        "list_id": "d7b66529-b722-494c-8792-6db0e98134c0"
      },
      "api_slug": "vcr_test_list_test_20250727122355_c9034f73",
      "created_at": "2025-07-27T12:23:55.323000000Z",
      "name": "VCR Test List test_20250727122355_c9034f73",
      "workspace_access": "full-access",
      "workspace_member_access": [],
      "parent_object": [
        "people"
      ],
      "created_by_actor": {
        "type": "api-token",
        "id": "4c9b8eb9-4b5d-4b27-a37c-6a9ff08bd3ee"
      }
    },
    {
      "id": {
        "workspace_id": "a96c9c20-442b-43cd-a94b-3d4683051661",
        "list_id": "ff4f3909-ac2a-4c02-8b2b-c26d882feb8c"
      },
      "api_slug": "vcr_test_list_test_20250727122700_6b9acb6d",
      "created_at": "2025-07-27T12:27:01.200000000Z",
      "name": "VCR Test List test_20250727122700_6b9acb6d",
      "workspace_access": "full-access",
      "workspace_member_access": [],
      "parent_object": [
        "people"
      ],
      "created_by_actor": {
        "type": "api-token",
        "id": "4c9b8eb9-4b5d-4b27-a37c-6a9ff08bd3ee"
      }
    },
    {
      "id": {
        "workspace_id": "a96c9c20-442b-43cd-a94b-3d4683051661",
        "list_id": "64feace7-86b3-4ea1-be35-2eed8f7a0adf"
      },
      "api_slug": "vcr_test_list_test_20250727124125_f49d0e6c",
      "created_at": "2025-07-27T12:41:25.523000000Z",
      "name": "VCR Test List test_20250727124125_f49d0e6c",
      "workspace_access": "full-access",
      "workspace_member_access": [],
      "parent_object": [
        "people"
      ],
      "created_by_actor": {
        "type": "api-token",
        "id": "4c9b8eb9-4b5d-4b27-a37c-6a9ff08bd3ee"
      }
    },
    {
      "id": {
        "workspace_id": "a96c9c20-442b-43cd-a94b-3d4683051661",
        "list_id": "a008d1f6-41f0-4072-aea9-6f637ee4ac63"
      },
      "api_slug": "vcr_test_list_test_20250727124501_5fde01de",
      "created_at": "2025-07-27T12:45:01.569000000Z",
      "name": "VCR Test List test_20250727124501_5fde01de",
      "workspace_access": "full-access",
      "workspace_member_access": [],
      "parent_object": [
        "people"
      ],
      "created_by_actor": {
        "type": "api-token",
        "id": "4c9b8eb9-4b5d-4b27-a37c-6a9ff08bd3ee"
      }
    },
    {
      "id": {
        "workspace_id": "a96c9c20-442b-43cd-a94b-3d4683051661",
        "list_id": "e2b38ef0-a766-44da-b409-9311d998c72c"
      },
      "api_slug": "vcr_test_list_test_20250727124802_9191a25a",
      "created_at": "2025-07-27T12:48:02.685000000Z",
      "name": "VCR Test List test_20250727124802_9191a25a",
      "workspace_access": "full-access",
      "workspace_member_access": [],
      "parent_object": [
        "people"
      ],
      "created_by_actor": {
        "type": "api-token",
        "id": "4c9b8eb9-4b5d-4b27-a37c-6a9ff08bd3ee"
      }
    },
    {
      "id": {
        "workspace_id": "a96c9c20-442b-43cd-a94b-3d4683051661",
        "list_id": "ab806f97-508d-4979-83f4-0c1547e1547c"
      },
      "api_slug": "vcr_test_list_test_20250727125151_e61ecaf0",
      "created_at": "2025-07-27T12:51:51.967000000Z",
      "name": "VCR Test List test_20250727125151_e61ecaf0",
      "workspace_access": "full-access",
      "workspace_member_access": [],
      "parent_object": [
        "people"
      ],
      "created_by_actor": {
        "type": "api-token",
        "id": "4c9b8eb9-4b5d-4b27-a37c-6a9ff08bd3ee"
      }
    },
    {
      "id": {
        "workspace_id": "a96c9c20-442b-43cd-a94b-3d4683051661",
        "list_id": "97daef10-84a8-440f-b090-854a92e5f70a"
      },
      "api_slug": "vcr_test_list_test_20250727091628_6b56ef2c",
      "created_at": "2025-07-27T13:16:28.826000000Z",
      "name": "VCR Test List test_20250727091628_6b56ef2c",
      "workspace_access": "full-access",
      "workspace_member_access": [],
      "parent_object": [
        "people"
      ],
      "created_by_actor": {
        "type": "api-token",
        "id": "4c9b8eb9-4b5d-4b27-a37c-6a9ff08bd3ee"
      }
    },
    {
      "id": {
        "workspace_id": "a96c9c20-442b-43cd-a94b-3d4683051661",
        "list_id": "b010ea4b-270f-4d82-a36f-4e6f9b5df80b"
      },
      "api_slug": "vcr_test_list_test_20250727091736_c18bccfd",
      "created_at": "2025-07-27T13:17:36.593000000Z",
      "name": "VCR Test List test_20250727091736_c18bccfd",
      "workspace_access": "full-access",
      "workspace_member_access": [],
      "parent_object": [
        "people"
      ],
      "created_by_actor": {
        "type": "api-token",
        "id": "4c9b8eb9-4b5d-4b27-a37c-6a9ff08bd3ee"
      }
    },
    {
      "id": {
        "workspace_id": "a96c9c20-442b-43cd-a94b-3d4683051661",
        "list_id": "81378acb-f401-4e43-9c7d-6de93b06e944"
      },
      "api_slug": "vcr_test_list_test_20250727131820_e57271ba",
      "created_at": "2025-07-27T13:18:20.578000000Z",
      "name": "VCR Test List test_20250727131820_e57271ba",
      "workspace_access": "full-access",
      "workspace_member_access": [],
      "parent_object": [
        "people"
      ],
      "created_by_actor": {
        "type": "api-token",
        "id": "4c9b8eb9-4b5d-4b27-a37c-6a9ff08bd3ee"
      }
    },
    {
      "id": {
        "workspace_id": "a96c9c20-442b-43cd-a94b-3d4683051661",
        "list_id": "1467254d-c90d-4632-b1a8-7bcdd0dc7b8f"
      },
      "api_slug": "vcr_test_list_test_20250727092333_0f386cb9",
      "created_at": "2025-07-27T13:23:33.416000000Z",
      "name": "VCR Test List test_20250727092333_0f386cb9",
      "workspace_access": "full-access",
      "workspace_member_access": [],
      "parent_object": [
        "people"
      ],
      "created_by_actor": {
        "type": "api-token",
        "id": "4c9b8eb9-4b5d-4b27-a37c-6a9ff08bd3ee"
      }
    },
    {
      "id": {
        "workspace_id": "a96c9c20-442b-43cd-a94b-3d4683051661",
        "list_id": "9b585d9e-1413-4d4c-b2fd-103dcd1d690a"
      },
      "api_slug": "vcr_test_list_test_20250727092918_b1e1a979",
      "created_at": "2025-07-27T13:29:19.100000000Z",
      "name": "VCR Test List test_20250727092918_b1e1a979",
      "workspace_access": "full-access",
      "workspace_member_access": [],
      "parent_object": [
        "people"
      ],
      "created_by_actor": {
        "type": "api-token",
        "id": "4c9b8eb9-4b5d-4b27-a37c-6a9ff08bd3ee"
      }
    },
    {
      "id": {
        "workspace_id": "a96c9c20-442b-43cd-a94b-3d4683051661",
        "list_id": "efcba0df-2d5e-43de-87e5-d7ee632766b9"
      },
      "api_slug": "vcr_test_list_test_20250727093554_ca67fdc3",
      "created_at": "2025-07-27T13:35:55.296000000Z",
      "name": "VCR Test List test_20250727093554_ca67fdc3",
      "workspace_access": "full-access",
      "workspace_member_access": [],
      "parent_object": [
        "people"
      ],
      "created_by_actor": {
        "type": "api-token",
        "id": "4c9b8eb9-4b5d-4b27-a37c-6a9ff08bd3ee"
      }
    },
    {
      "id": {
        "workspace_id": "a96c9c20-442b-43cd-a94b-3d4683051661",
        "list_id": "73eeabb0-84a6-408c-8628-68f7f61cbba9"
      },
      "api_slug": "vcr_test_list_test_20250727093645_c813fd1d",
      "created_at": "2025-07-27T13:36:45.895000000Z",
      "name": "VCR Test List test_20250727093645_c813fd1d",
      "workspace_access": "full-access",
      "workspace_member_access": [],
      "parent_object": [
        "people"
      ],
      "created_by_actor": {
        "type": "api-token",
        "id": "4c9b8eb9-4b5d-4b27-a37c-6a9ff08bd3ee"
      }
    },
    {
      "id": {
        "workspace_id": "a96c9c20-442b-43cd-a94b-3d4683051661",
        "list_id": "12b55964-5def-4f28-a091-d77707e2363b"
      },
      "api_slug": "vcr_test_list_test_20250727093854_0caf2aec",
      "created_at": "2025-07-27T13:38:54.954000000Z",
      "name": "VCR Test List test_20250727093854_0caf2aec",
      "workspace_access": "full-access",
      "workspace_member_access": [],
      "parent_object": [
        "people"
      ],
      "created_by_actor": {
        "type": "api-token",
        "id": "4c9b8eb9-4b5d-4b27-a37c-6a9ff08bd3ee"
      }
    },
    {
      "id": {
        "workspace_id": "a96c9c20-442b-43cd-a94b-3d4683051661",
        "list_id": "8b9198c5-4d9f-41ba-b9f9-a891b26754e9"
      },
      "api_slug": "vcr_test_list_test_20250727093940_a4ecc153",
      "created_at": "2025-07-27T13:39:40.999000000Z",
      "name": "VCR Test List test_20250727093940_a4ecc153",
      "workspace_access": "full-access",
      "workspace_member_access": [],
      "parent_object": [
        "people"
      ],
      "created_by_actor": {
        "type": "api-token",
        "id": "4c9b8eb9-4b5d-4b27-a37c-6a9ff08bd3ee"
      }
    }
  ]
}
```
