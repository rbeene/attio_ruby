# frozen_string_literal: true

module Attio
  # HTTP Methods
  module HTTPMethods
    GET = :GET
    POST = :POST
    PUT = :PUT
    PATCH = :PATCH
    DELETE = :DELETE
  end

  # HTTP Status Codes
  module HTTPStatus
    OK = 200
    CREATED = 201
    NO_CONTENT = 204
    BAD_REQUEST = 400
    UNAUTHORIZED = 401
    FORBIDDEN = 403
    NOT_FOUND = 404
    CONFLICT = 409
    UNPROCESSABLE_ENTITY = 422
    TOO_MANY_REQUESTS = 429
    INTERNAL_SERVER_ERROR = 500
    BAD_GATEWAY = 502
    SERVICE_UNAVAILABLE = 503
    GATEWAY_TIMEOUT = 504
  end

  # API Configuration
  module APIDefaults
    BASE_URL = "https://api.attio.com"
    API_VERSION = "v2"
    DEFAULT_TIMEOUT = 120 # seconds
    MAX_RETRIES = 3
    RETRY_DELAY = 1 # seconds
  end

  # Content Types
  module ContentTypes
    JSON = "application/json"
    FORM_URLENCODED = "application/x-www-form-urlencoded"
  end

  # Format Types
  module FormatTypes
    PLAINTEXT = "plaintext"
    HTML = "html"
  end

  # Resource States
  module ResourceStates
    ACTIVE = "active"
    PAUSED = "paused"
    ARCHIVED = "archived"
  end

  # Workspace Access Levels
  module WorkspaceAccess
    FULL_ACCESS = "full-access"
    READ_ONLY = "read-only"
    NO_ACCESS = "no-access"
  end

  # Sort Directions
  module SortDirection
    ASC = "asc"
    DESC = "desc"
  end

  # Default Limits
  module Limits
    DEFAULT_PAGE_SIZE = 50
    MAX_PAGE_SIZE = 500
    MAX_BATCH_SIZE = 100
  end

  # Time Constants
  module TimeConstants
    WEBHOOK_TOLERANCE_SECONDS = 300 # 5 minutes
    TOKEN_REFRESH_BUFFER = 300 # 5 minutes before expiry
  end

  # API Paths
  module APIPaths
    OAUTH_AUTHORIZE = "/authorize"
    OAUTH_TOKEN = "/oauth/token"
    OAUTH_REVOKE = "/oauth/revoke"
  end

  # Field Names
  module FieldNames
    ID = "id"
    CREATED_AT = "created_at"
    UPDATED_AT = "updated_at"
    DATA = "data"
    NEXT_CURSOR = "next_cursor"
    PREVIOUS_CURSOR = "previous_cursor"
  end

  # Error Messages
  module ErrorMessages
    MISSING_API_KEY = "API key is required but not configured"
    INVALID_API_KEY = "Invalid API key provided"
    RATE_LIMITED = "Rate limit exceeded. Please retry after some time"
    NETWORK_ERROR = "Network error occurred while making the request"
    TIMEOUT_ERROR = "Request timed out"
    PARSING_ERROR = "Failed to parse response body"
  end
end
