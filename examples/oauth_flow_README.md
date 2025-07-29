# Attio OAuth Flow Example

This example demonstrates how to implement the OAuth 2.0 authorization code flow with the Attio API.

## Setup

1. Create an OAuth app in your Attio workspace settings
2. Set up your environment variables in `.env`:
   ```
   ATTIO_CLIENT_ID=your_client_id
   ATTIO_CLIENT_SECRET=your_client_secret
   ATTIO_REDIRECT_URI=http://localhost:4567/callback
   ```

3. Add redirect URIs to your Attio app:
   - `http://localhost:4567/callback` (for local development)
   - `https://your-ngrok-domain.ngrok.dev/callback` (if using ngrok)

## Running the Example

```bash
# Run the OAuth example server
ruby examples/oauth_flow.rb

# Or with bundler
bundle exec ruby examples/oauth_flow.rb

# Or using rackup
bundle exec rackup config.ru -p 4567
```

## Available Routes

### Public Routes (No Authentication Required)
- `GET /` - Home page with login/status
- `GET /auth` - Start OAuth flow (redirects to Attio)
- `GET /callback` - OAuth callback handler

### Protected Routes (Requires Authentication)
- `GET /test` - Basic API test (lists objects, people, companies, etc.)
- `GET /test-all` - Comprehensive API test with CRUD operations
- `GET /introspect` - View detailed token information
- `GET /revoke` - Revoke token on Attio's servers
- `GET /logout` - Clear local session only

## Features Demonstrated

1. **OAuth Authorization Flow**
   - Generating authorization URLs with state parameter
   - Handling OAuth callbacks
   - Exchanging authorization codes for tokens
   - Token storage (in-memory for demo)

2. **API Testing**
   - Basic test: Read operations across multiple endpoints
   - Comprehensive test: Full CRUD operations with cleanup
   - Error handling and permission checking

3. **Token Management**
   - Token introspection
   - Token revocation
   - Session management
   - Token refresh on 401 (automatic retry)

## Using with ngrok

If you need to test with ngrok (for example, to test with a real Attio OAuth app):

```bash
# Start ngrok
ngrok http 4567

# Update your .env with the ngrok URL
ATTIO_REDIRECT_URI=https://your-subdomain.ngrok.dev/callback
```

## Security Notes

This example uses in-memory token storage for simplicity. In production:
- Use secure session storage
- Encrypt tokens at rest
- Implement CSRF protection
- Use secure cookies with httpOnly flag
- Implement proper state validation