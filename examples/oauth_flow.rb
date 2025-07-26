#!/usr/bin/env ruby
# frozen_string_literal: true

require "bundler/setup"
require "attio"
require "sinatra"
require "dotenv/load"

# OAuth flow example using Sinatra

# OAuth client configuration
oauth_client = Attio::OAuth::Client.new(
  client_id: ENV["ATTIO_CLIENT_ID"],
  client_secret: ENV["ATTIO_CLIENT_SECRET"],
  redirect_uri: "http://localhost:4567/callback"
)

# Store tokens in memory (use a proper store in production)
$token_store = {}

get "/" do
  <<~HTML
    <h1>Attio OAuth Example</h1>
    <p>This example demonstrates the OAuth 2.0 flow for Attio.</p>
    <a href="/auth">Connect to Attio</a>
    <hr>
    #{$token_store[:access_token] ? "<p>✅ Connected! <a href='/test'>Test API</a></p>" : "<p>❌ Not connected</p>"}
  HTML
end

# Step 1: Redirect to Attio authorization page
get "/auth" do
  auth_data = oauth_client.authorization_url(
    scopes: %w[record:read record:write user:read],
    state: SecureRandom.hex(16)
  )
  
  # Store state for verification (use session in production)
  $token_store[:state] = auth_data[:state]
  
  redirect auth_data[:url]
end

# Step 2: Handle callback from Attio
get "/callback" do
  # Verify state parameter
  if params[:state] != $token_store[:state]
    return "Error: Invalid state parameter"
  end
  
  # Check for errors
  if params[:error]
    return "Error: #{params[:error]} - #{params[:error_description]}"
  end
  
  # Exchange authorization code for token
  begin
    token = oauth_client.exchange_code_for_token(code: params[:code])
    
    # Store token (use secure storage in production)
    $token_store[:access_token] = token.access_token
    $token_store[:refresh_token] = token.refresh_token
    $token_store[:expires_at] = token.expires_at
    
    <<~HTML
      <h1>Success!</h1>
      <p>Successfully connected to Attio.</p>
      <p>Access token: #{token.access_token[0..10]}...</p>
      <p>Expires at: #{token.expires_at}</p>
      <p>Scopes: #{token.scope.join(', ')}</p>
      <a href="/test">Test API Access</a>
    HTML
  rescue => e
    "Error exchanging code: #{e.message}"
  end
end

# Test API access with the token
get "/test" do
  unless $token_store[:access_token]
    redirect "/"
    return
  end
  
  # Configure Attio with the OAuth token
  Attio.configure do |config|
    config.api_key = $token_store[:access_token]
  end
  
  begin
    # Get current user
    me = Attio::WorkspaceMember.me
    
    # List some records
    people = Attio::Record.list(object: "people", params: { limit: 5 })
    
    <<~HTML
      <h1>API Test Results</h1>
      <h2>Current User</h2>
      <p>Name: #{me.full_name}</p>
      <p>Email: #{me.email_address}</p>
      <p>Access Level: #{me.access_level}</p>
      
      <h2>Recent People</h2>
      <ul>
        #{people.map { |p| "<li>#{p[:name]} - #{p[:email_addresses]}</li>" }.join}
      </ul>
      
      <a href="/">Back</a>
    HTML
  rescue Attio::Errors::AuthenticationError => e
    # Token might be expired, try to refresh
    if $token_store[:refresh_token]
      begin
        new_token = oauth_client.refresh_token($token_store[:refresh_token])
        $token_store[:access_token] = new_token.access_token
        $token_store[:refresh_token] = new_token.refresh_token if new_token.refresh_token
        redirect "/test"
      rescue
        "Token refresh failed. <a href='/auth'>Re-authenticate</a>"
      end
    else
      "Authentication failed. <a href='/auth'>Re-authenticate</a>"
    end
  rescue => e
    "Error: #{e.message}"
  end
end

# Revoke token
get "/revoke" do
  if $token_store[:access_token]
    success = oauth_client.revoke_token($token_store[:access_token])
    $token_store.clear
    "Token revoked: #{success}. <a href='/'>Home</a>"
  else
    redirect "/"
  end
end

# Token introspection
get "/introspect" do
  if $token_store[:access_token]
    info = oauth_client.introspect_token($token_store[:access_token])
    <<~HTML
      <h1>Token Information</h1>
      <pre>#{JSON.pretty_generate(info)}</pre>
      <a href="/">Back</a>
    HTML
  else
    redirect "/"
  end
end

# Run the app
if __FILE__ == $0
  puts "=== Attio OAuth Example ==="
  puts "Starting server on http://localhost:4567"
  puts
  puts "Make sure you have set up:"
  puts "1. ATTIO_CLIENT_ID and ATTIO_CLIENT_SECRET in .env"
  puts "2. Redirect URI in Attio app settings: http://localhost:4567/callback"
  puts
  
  # Run Sinatra
  set :port, 4567
  run!
end