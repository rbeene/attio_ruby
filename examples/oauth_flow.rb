#!/usr/bin/env ruby
# frozen_string_literal: true

require "bundler/setup"
require "attio"
require "sinatra"
require "dotenv/load"
require "securerandom"

# OAuth flow example using Sinatra

class OAuthApp < Sinatra::Base
  # Configure for development
  configure do
    set :protection, true
    set :host_authorization, {
      permitted_hosts: [] # Allow any hostname
    }
    set :static, false
    set :session_secret, "a" * 64  # Simple secret for development
    set :environment, :development
    set :show_exceptions, true
  end
  # OAuth client configuration
  def oauth_client(request = nil)
    # Always use the ngrok URL from environment
    redirect_uri = ENV.fetch("ATTIO_REDIRECT_URI", "http://localhost:4567/callback")

    Attio::OAuth::Client.new(
      client_id: ENV.fetch("ATTIO_CLIENT_ID", nil),
      client_secret: ENV.fetch("ATTIO_CLIENT_SECRET", nil),
      redirect_uri: redirect_uri
    )
  end

  # Store tokens in memory (use a proper store in production)
  @@token_store = {}

  # Add ngrok warning bypass for all routes
  before do
    headers["ngrok-skip-browser-warning"] = "true"
  end

  get "/" do
    <<~HTML
      <h1>Attio OAuth Example</h1>
      <p>This example demonstrates the OAuth 2.0 flow for Attio.</p>
      <a href="/auth">Connect to Attio</a>
      <hr>
      #{if @@token_store[:access_token]
          "<p>✅ Connected!</p>
          <h3>API Tests</h3>
          <p>
            <a href='/test'>Basic Test</a> | 
            <a href='/test-all'>Comprehensive Test</a> | 
            <a href='/test-note'>Test Note Creation</a>
          </p>
          <h3>Token Management</h3>
          <p>
            <a href='/introspect'>Token Info</a> | 
            <a href='/revoke'>Revoke Token</a> | 
            <a href='/logout'>Logout</a>
          </p>"
        else
          "<p>❌ Not connected</p>"
        end}
    HTML
  end

  # Step 1: Redirect to Attio authorization page
  get "/auth" do
    client = oauth_client(request)

    puts "\n=== AUTH START DEBUG ==="
    puts "Redirect URI configured: #{ENV.fetch("ATTIO_REDIRECT_URI", "NOT SET")}"
    puts "Client ID: #{ENV.fetch("ATTIO_CLIENT_ID", "NOT SET")}"
    puts "Request host: #{request.host}"
    puts "Request scheme: #{request.scheme}"

    auth_data = client.authorization_url(
      scopes: %w[record:read record:write user:read],
      state: SecureRandom.hex(16)
    )

    # Store state for verification (use session in production)
    @@token_store[:state] = auth_data[:state]

    puts "Generated state: #{auth_data[:state]}"
    puts "Authorization URL: #{auth_data[:url]}"
    puts "===================\n"

    redirect auth_data[:url]
  end

  # Step 2: Handle callback from Attio
  get "/callback" do
    # Log all callback parameters
    puts "\n=== CALLBACK DEBUG ==="
    puts "All params: #{params.inspect}"
    puts "Request URL: #{request.url}"
    puts "Request host: #{request.host}"
    puts "Request scheme: #{request.scheme}"
    puts "Stored state: #{@@token_store[:state]}"
    puts "Received state: #{params[:state]}"
    puts "Authorization code: #{params[:code]}"
    puts "Error: #{params[:error]}" if params[:error]
    puts "Error description: #{params[:error_description]}" if params[:error_description]

    # Verify state parameter
    if params[:state] != @@token_store[:state]
      puts "STATE MISMATCH! Expected: #{@@token_store[:state]}, Got: #{params[:state]}"
      return "Error: Invalid state parameter"
    end

    # Check for errors
    return "Error: #{params[:error]} - #{params[:error_description]}" if params[:error]

    # Exchange authorization code for token
    begin
      client = oauth_client(request)
      puts "\n=== OAUTH CLIENT DEBUG ==="
      puts "Client ID: #{ENV.fetch("ATTIO_CLIENT_ID", "NOT SET")}"
      puts "Client Secret: #{ENV.fetch("ATTIO_CLIENT_SECRET", "NOT SET")[0..5]}..." if ENV["ATTIO_CLIENT_SECRET"]
      puts "Redirect URI being used: #{ENV.fetch("ATTIO_REDIRECT_URI", "NOT SET")}"
      puts "Code being exchanged: #{params[:code]}"

      token = client.exchange_code_for_token(code: params[:code])

      # Store token (use secure storage in production)
      @@token_store[:access_token] = token.access_token
      @@token_store[:refresh_token] = token.refresh_token
      @@token_store[:expires_at] = token.expires_at

      puts "\n=== TOKEN RECEIVED ==="
      puts "Access token: #{token.access_token[0..20]}..."
      puts "Token scopes: #{token.scope.inspect}"
      puts "Token scope class: #{token.scope.class}"
      puts "Raw token data: #{token.to_h.inspect}"
      puts "=====================\n"

      <<~HTML
        <h1>Success!</h1>
        <p>Successfully connected to Attio.</p>
        <p>Access token: #{token.access_token[0..10]}...</p>
        <p>Expires at: #{token.expires_at}</p>
        <p>Scopes: #{if token.scope.nil?
                       "All authorized scopes (not specified in token)"
                     elsif token.scope.is_a?(Array)
                       token.scope.empty? ? "None" : token.scope.join(", ")
                     else
                       token.scope
                     end}</p>
        <h3>What's Next?</h3>
        <p>
          <a href="/test">Run Basic Test</a> | 
          <a href="/test-all">Run Comprehensive Test</a> | 
          <a href="/introspect">View Token Info</a>
        </p>
        <p><a href="/">← Back to Home</a></p>
      HTML
    rescue => e
      puts "\n=== OAUTH ERROR DETAILS ==="
      puts "Error class: #{e.class}"
      puts "Error message: #{e.message}"
      puts "Error backtrace:"
      puts e.backtrace[0..5].join("\n")

      # If it's an HTTP error, try to get more details
      if e.respond_to?(:response)
        puts "\nHTTP Response details:"
        puts "Status: #{e.response[:status] if e.response.is_a?(Hash)}"
        puts "Body: #{e.response[:body] if e.response.is_a?(Hash)}"
      end

      <<~HTML
        <h1>OAuth Error</h1>
        <p><strong>Error:</strong> #{e.class} - #{e.message}</p>
        <p>Check the server logs for detailed debugging information.</p>
        <pre>#{e.backtrace[0..5].join("\n")}</pre>
      HTML
    end
  end

  # Test API access with the token
  get "/test" do
    unless @@token_store[:access_token]
      redirect "/"
      return
    end

    # Configure Attio with the OAuth token
    Attio.configure do |config|
      config.api_key = @@token_store[:access_token]
    end

    begin
      puts "\n=== API TEST DEBUG ==="
      puts "Using access token: #{@@token_store[:access_token][0..20]}..."
      puts "Token stored at: #{@@token_store[:expires_at]}"

      results = {}
      errors = {}

      # Test 1: Get current user/workspace info
      begin
        me = Attio::Meta.identify
        results[:meta] = {workspace: me.workspace_name, token_type: me.token_type}
        puts "✓ Meta.identify successful"
      rescue => e
        errors[:meta] = e.message
        puts "✗ Meta.identify failed: #{e.message}"
      end

      # Test 2: List Objects
      begin
        objects = Attio::Object.list(limit: 3)
        results[:objects] = objects.map { |o| o[:api_slug] }
        puts "✓ Object.list successful (#{objects.count} objects)"
      rescue => e
        errors[:objects] = e.message
        puts "✗ Object.list failed: #{e.message}"
      end

      # Test 3: List People Records
      begin
        people = Attio::Person.list(limit: 3)
        results[:people] = people.count
        puts "✓ Person.list successful (#{people.count} records)"
      rescue => e
        errors[:people] = e.message
        puts "✗ Person.list failed: #{e.message}"
      end

      # Test 4: List Companies Records
      begin
        companies = Attio::Company.list(limit: 3)
        results[:companies] = companies.count
        puts "✓ Company.list successful (#{companies.count} records)"
      rescue => e
        errors[:companies] = e.message
        puts "✗ Company.list failed: #{e.message}"
      end

      # Test 5: List Lists
      begin
        lists = Attio::List.list(limit: 3)
        results[:lists] = lists.map { |l| l[:name] }
        puts "✓ List.list successful (#{lists.count} lists)"
      rescue => e
        errors[:lists] = e.message
        puts "✗ List.list failed: #{e.message}"
      end

      # Test 6: List Workspace Members
      begin
        members = Attio::WorkspaceMember.list(limit: 3)
        results[:members] = members.count
        puts "✓ WorkspaceMember.list successful (#{members.count} members)"
      rescue => e
        errors[:members] = e.message
        puts "✗ WorkspaceMember.list failed: #{e.message}"
      end

      # Test 7: List Webhooks
      begin
        webhooks = Attio::Webhook.list(limit: 3)
        results[:webhooks] = webhooks.count
        puts "✓ Webhook.list successful (#{webhooks.count} webhooks)"
      rescue => e
        errors[:webhooks] = e.message
        puts "✗ Webhook.list failed: #{e.message}"
      end

      # Test 8: List Notes
      begin
        # Try to get notes for the first person if we have one
        if results[:people] && results[:people] > 0 && people.first
          notes = Attio::Note.list(
            parent_object: "people",
            parent_record_id: people.first.id["record_id"],
            limit: 3
          )
          results[:notes] = notes.count
          puts "✓ Note.list successful (#{notes.count} notes)"
        else
          results[:notes] = "No people to test with"
        end
      rescue => e
        errors[:notes] = e.message
        puts "✗ Note.list failed: #{e.message}"
      end

      puts "===================\n"

      # Generate HTML results
      html_results = results.map do |key, value|
        status = errors[key] ? "❌" : "✅"
        details = errors[key] || value.to_s
        "<tr><td>#{status}</td><td>#{key.to_s.capitalize}</td><td>#{details}</td></tr>"
      end.join("\n")

      <<~HTML
        <h1>Comprehensive API Test Results</h1>
        #{if results[:meta]
            "<h2>Workspace: #{results[:meta][:workspace]}</h2>"
          else
            "<h2>Could not retrieve workspace info</h2>"
          end}
        
        <table border="1" cellpadding="5" cellspacing="0">
          <thead>
            <tr>
              <th>Status</th>
              <th>Endpoint</th>
              <th>Result</th>
            </tr>
          </thead>
          <tbody>
            #{html_results}
          </tbody>
        </table>
        
        <p>Tests passed: #{results.count - errors.count} / #{results.count}</p>
        
        <p><a href="/">Home</a> | <a href="/logout">Logout</a></p>
      HTML
    rescue Attio::PermissionError => e
      puts "\n=== PERMISSION ERROR ==="
      puts "Error: #{e.message}"
      puts "This suggests the token doesn't have the required scopes"
      puts "===================\n"

      <<~HTML
        <h1>Permission Error</h1>
        <p>Error: #{e.message}</p>
        <p>The access token doesn't have the required permissions.</p>
        <p>This usually means the OAuth app needs the proper scopes configured in Attio.</p>
        <p><a href="/">Home</a> | <a href="/logout">Logout</a></p>
      HTML
    rescue Attio::AuthenticationError
      # Token might be expired, try to refresh
      if @@token_store[:refresh_token]
        begin
          new_token = oauth_client(request).refresh_token(@@token_store[:refresh_token])
          @@token_store[:access_token] = new_token.access_token
          @@token_store[:refresh_token] = new_token.refresh_token if new_token.refresh_token
          redirect "/test"
        rescue
          "Token refresh failed. <a href='/auth'>Re-authenticate</a> | <a href='/logout'>Logout</a>"
        end
      else
        "Authentication failed. <a href='/auth'>Re-authenticate</a> | <a href='/logout'>Logout</a>"
      end
    rescue => e
      "Error: #{e.message}"
    end
  end

  # Comprehensive API test
  get "/test-all" do
    unless @@token_store[:access_token]
      redirect "/"
      return
    end

    Attio.configure do |config|
      config.api_key = @@token_store[:access_token]
    end

    results = {}
    errors = {}
    created_resources = []

    begin
      # Get current user info first
      me = Attio::Meta.identify
      results[:meta] = {workspace: me.workspace_name, token_type: me.token_type}

      # Test 1: List Objects
      begin
        objects = Attio::Object.list(limit: 3)
        results[:list_objects] = "#{objects.count} objects"
        puts "✓ Object.list successful"
      rescue => e
        errors[:list_objects] = e.message
        puts "✗ Object.list failed: #{e.message}"
      end

      # Test 2: List Attributes
      begin
        attributes = Attio::Attribute.for_object("people", limit: 5)
        results[:list_attributes] = "#{attributes.count} attributes"
        puts "✓ Attribute.for_object successful"
      rescue => e
        errors[:list_attributes] = e.message
        puts "✗ Attribute.for_object failed: #{e.message}"
      end

      # Test 3: Create a Person
      person = nil
      begin
        person = Attio::Person.create(
          first_name: "OAuth",
          last_name: "Test #{Time.now.to_i}",
          email: "oauth-#{Time.now.to_i}@example.com"
        )
        created_resources << {type: "person", id: person.id["record_id"]}
        results[:create_person] = "Created person ID: #{person.id["record_id"][0..10]}..."
        puts "✓ Person.create successful"
      rescue => e
        errors[:create_person] = e.message
        puts "✗ Person.create failed: #{e.message}"
      end

      # Test 4: Create a Note
      if person
        begin
          puts "\nDEBUG Note.create:"
          puts "  person.id: #{person.id.inspect}"
          puts "  person.id['record_id']: #{person.id["record_id"].inspect}"

          Attio::Note.create(
            parent_object: "people",
            parent_record_id: person.id["record_id"],
            content: "Test note created via OAuth at #{Time.now}",
            format: "plaintext"
          )
          results[:create_note] = "Created note on person"
          puts "✓ Note.create successful"
        rescue => e
          errors[:create_note] = e.message
          puts "✗ Note.create failed: #{e.message}"
          puts "  Error class: #{e.class}"
          puts "  Error backtrace: #{e.backtrace[0..2].join("\n  ")}" if e.backtrace
        end
      end

      # Test 5: List and Create Tasks
      begin
        # Create a task
        task = Attio::Task.create(
          content: "OAuth test task - #{Time.now}",
          deadline_at: Time.now + 86400
        )
        created_resources << {type: "task", id: task.id}
        results[:create_task] = "Created task"

        # List tasks
        tasks = Attio::Task.list(limit: 5)
        results[:list_tasks] = "#{tasks.count} tasks found"
        puts "✓ Task operations successful"
      rescue => e
        errors[:task_ops] = e.message
        puts "✗ Task operations failed: #{e.message}"
      end

      # Test 6: List Threads
      threads = nil
      begin
        # Threads require either record_id or entry_id to query
        if person
          threads = Attio::Thread.list(
            object: "people",
            record_id: person.id["record_id"],
            limit: 3
          )
          results[:list_threads] = "#{threads.count} threads for person"
          puts "✓ Thread.list successful"
        else
          results[:list_threads] = "Skipped - no person to query"
        end
      rescue => e
        errors[:list_threads] = e.message
        puts "✗ Thread.list failed: #{e.message}"
      end

      # Test 7: Create Comment (if thread exists)
      if threads&.first && me.actor
        begin
          Attio::Comment.create(
            thread_id: threads.first.id,
            content: "OAuth test comment - #{Time.now}",
            author: {
              type: "workspace-member",
              id: me.actor["id"]
            }
          )
          results[:create_comment] = "Created comment in thread"
          puts "✓ Comment.create successful"
        rescue => e
          errors[:create_comment] = e.message
          puts "✗ Comment.create failed: #{e.message}"
        end
      end

      # Test 8: List and Work with Lists
      lists = nil
      begin
        lists = Attio::List.list(limit: 3)
        results[:list_lists] = "#{lists.count} lists"
        puts "✓ List.list successful"
      rescue => e
        errors[:list_lists] = e.message
        puts "✗ List.list failed: #{e.message}"
      end

      # Test 9: Work with List Entries
      if lists&.first && person
        begin
          # Extract list_id from the nested ID structure
          list_id = lists.first.id.is_a?(Hash) ? lists.first.id["list_id"] : lists.first.id

          # Check if the list supports people objects
          # If it doesn't, we'll get an error, but let's try anyway
          begin
            # Add person to list
            entry = Attio::Entry.create(
              list: list_id,
              parent_object: "people",
              parent_record_id: person.id["record_id"]
            )
            created_resources << {type: "entry", id: entry.id, list_id: list_id}
            results[:create_entry] = "Added person to list"
          rescue Attio::BadRequestError => e
            if e.message.include?("does not allow")
              results[:create_entry] = "List doesn't support people objects"
            else
              raise e
            end
          end

          # List entries regardless of whether we could add one
          entries = Attio::Entry.list(list: list_id, limit: 5)
          results[:list_entries] = "#{entries.count} entries in list"
          puts "✓ Entry operations successful"
        rescue => e
          errors[:entry_ops] = e.message
          puts "✗ Entry operations failed: #{e.message}"
        end
      end

      # Test 10: Workspace Members
      begin
        members = Attio::WorkspaceMember.list(limit: 5)
        results[:list_members] = "#{members.count} workspace members"
        puts "✓ WorkspaceMember.list successful"
      rescue => e
        errors[:list_members] = e.message
        puts "✗ WorkspaceMember.list failed: #{e.message}"
      end

      # Test 11: Webhooks
      begin
        webhooks = Attio::Webhook.list(limit: 5)
        results[:list_webhooks] = "#{webhooks.count} webhooks"
        puts "✓ Webhook.list successful"
      rescue => e
        errors[:list_webhooks] = e.message
        puts "✗ Webhook.list failed: #{e.message}"
      end

      # Test 12: Update Operations
      if person
        begin
          person.set_name(
            first: "OAuth",
            last: "Test Updated #{Time.now.to_i}"
          )
          person.save
          results[:update_record] = "Updated person name"
          puts "✓ Person.update successful"
        rescue => e
          errors[:update_record] = e.message
          puts "✗ Person.update failed: #{e.message}"
        end
      end

      # Test 13: Error Handling
      begin
        # Use a properly formatted UUID that doesn't exist
        Attio::Person.retrieve("00000000-0000-0000-0000-000000000000")
      rescue Attio::NotFoundError => e
        results[:error_handling] = "404 errors handled correctly"
        puts "✓ Error handling working correctly"
      rescue => e
        errors[:error_handling] = "Unexpected error type: #{e.class}"
        puts "✗ Error handling issue: #{e.message}"
      end

      # Test 14: Token Introspection
      begin
        token_info = oauth_client(request).introspect_token(@@token_store[:access_token])
        results[:token_introspection] = token_info[:active] ? "Token is active" : "Token is inactive"
        puts "✓ Token introspection successful"
      rescue => e
        errors[:token_introspection] = e.message
        puts "✗ Token introspection failed: #{e.message}"
      end

      # Test 15: Cleanup created resources
      cleanup_count = 0
      created_resources.each do |resource|
        case resource[:type]
        when "person"
          # Need to retrieve the record first to call destroy on the instance
          record = Attio::Person.retrieve(resource[:id])
          record.destroy
          cleanup_count += 1
        when "task"
          # Extract task_id from the nested ID structure
          task_id = if resource[:id].is_a?(Hash)
            resource[:id]["task_id"] || resource[:id]
          else
            resource[:id]
          end
          task = Attio::Task.retrieve(task_id)
          task.destroy
          cleanup_count += 1
        when "entry"
          entry = Attio::Entry.retrieve(list: resource[:list_id], entry_id: resource[:id])
          entry.destroy
          cleanup_count += 1
        end
      rescue => e
        puts "Failed to cleanup #{resource[:type]}: #{e.message}"
      end
      results[:cleanup] = "Cleaned up #{cleanup_count} test resources"

      # Generate HTML report
      total_tests = results.count + errors.count
      passed_tests = results.count

      test_rows = results.merge(errors).map do |key, value|
        status = errors[key] ? "❌" : "✅"
        result = errors[key] || value
        category = case key.to_s
        when /list_/ then "List Operations"
        when /create_/ then "Create Operations"
        when /update_/ then "Update Operations"
        when /token_/ then "Token Operations"
        else "Other"
        end

        "<tr>
          <td>#{status}</td>
          <td>#{category}</td>
          <td>#{key.to_s.split("_").map(&:capitalize).join(" ")}</td>
          <td>#{result}</td>
        </tr>"
      end.join("\n")

      <<~HTML
        <h1>Comprehensive API Test Results</h1>
        <h2>Workspace: #{results[:meta][:workspace] if results[:meta]}</h2>
        
        <div style="background: #f0f0f0; padding: 10px; margin: 10px 0;">
          <strong>Summary:</strong> #{passed_tests} / #{total_tests} tests passed
          #{errors.any? ? "<br><strong style='color: red;'>#{errors.count} tests failed</strong>" : "<br><strong style='color: green;'>All tests passed! 🎉</strong>"}
        </div>
        
        <table border="1" cellpadding="5" cellspacing="0" style="width: 100%;">
          <thead>
            <tr style="background: #e0e0e0;">
              <th width="50">Status</th>
              <th width="150">Category</th>
              <th width="200">Test</th>
              <th>Result</th>
            </tr>
          </thead>
          <tbody>
            #{test_rows}
          </tbody>
        </table>
        
        <h3>Test Categories</h3>
        <ul>
          <li><strong>List Operations:</strong> Reading data from various endpoints</li>
          <li><strong>Create Operations:</strong> Creating new resources</li>
          <li><strong>Update Operations:</strong> Modifying existing resources</li>
          <li><strong>Token Operations:</strong> OAuth token management</li>
          <li><strong>Other:</strong> Error handling, cleanup, etc.</li>
        </ul>
        
        <p style="margin-top: 20px;">
          <a href="/">Home</a> | 
          <a href="/test">Basic Test</a> | 
          <a href="/logout">Logout</a>
        </p>
      HTML
    rescue => e
      <<~HTML
        <h1>Test Error</h1>
        <p>An unexpected error occurred while running tests:</p>
        <pre>#{e.class}: #{e.message}
        #{e.backtrace[0..5].join("\n")}</pre>
        <p><a href="/">Home</a> | <a href="/logout">Logout</a></p>
      HTML
    end
  end

  # Test Note creation specifically
  get "/test-note" do
    unless @@token_store[:access_token]
      redirect "/"
      return
    end

    Attio.configure do |config|
      config.api_key = @@token_store[:access_token]
    end

    begin
      # Create a test person first
      timestamp = Time.now.to_i
      person = Attio::Person.create(
        first_name: "Note",
        last_name: "Test#{timestamp}",
        email: "note-test-#{timestamp}@example.com"
      )

      result_html = "<h1>Note Creation Test</h1>"
      result_html += "<h2>Step 1: Created Person</h2>"
      result_html += "<pre>ID: #{person.id.inspect}\nrecord_id: #{person.id["record_id"]}</pre>"

      # Try to create a note
      begin
        note = Attio::Note.create({
          parent_object: "people",
          parent_record_id: person.id["record_id"],
          content: "Test note created at #{Time.now}",
          format: "plaintext"
        })

        result_html += "<h2>Step 2: Created Note ✅</h2>"
        result_html += "<pre>Note ID: #{note.id.inspect}\nContent: #{note.content}</pre>"
      rescue => e
        result_html += "<h2>Step 2: Note Creation Failed ❌</h2>"
        result_html += "<pre>Error: #{e.class} - #{e.message}\n"
        result_html += "Backtrace:\n#{e.backtrace[0..5].join("\n")}</pre>" if e.backtrace
      end

      # Clean up
      begin
        person.destroy
      rescue
        nil
      end
      result_html += "<h2>Step 3: Cleanup Complete</h2>"

      result_html += '<p><a href="/">← Back to Home</a></p>'
      result_html
    rescue => e
      <<~HTML
        <h1>Test Error</h1>
        <pre>#{e.class}: #{e.message}
        #{e.backtrace[0..5].join("\n") if e.backtrace}</pre>
        <p><a href="/">← Back to Home</a></p>
      HTML
    end
  end

  # Logout - Clear local tokens
  get "/logout" do
    @@token_store.clear
    redirect "/"
  end

  # Revoke token (actually revokes on Attio's side)
  get "/revoke" do
    if @@token_store[:access_token]
      success = oauth_client(request).revoke_token(@@token_store[:access_token])
      @@token_store.clear
      <<~HTML
        <h1>Token Revoked</h1>
        <p>#{success ? "✅ Token successfully revoked on Attio's servers." : "⚠️ Token revocation may have failed."}</p>
        <p>The local session has been cleared.</p>
        <p><a href="/">← Back to Home</a></p>
      HTML
    else
      redirect "/"
    end
  end

  # Token introspection
  get "/introspect" do
    if @@token_store[:access_token]
      info = oauth_client(request).introspect_token(@@token_store[:access_token])
      <<~HTML
        <h1>Token Information</h1>
        <pre>#{JSON.pretty_generate(info)}</pre>
        <a href="/">Back</a>
      HTML
    else
      redirect "/"
    end
  end

  # Configure the app
  set :port, 4567
  set :bind, "0.0.0.0"
  set :environment, :development
  set :sessions, false  # Disable sessions to avoid the encryptor issue
end

# Run the app
if __FILE__ == $0
  puts "=== Attio OAuth Example ==="
  puts "Starting server on http://localhost:4567"
  puts "Also accessible via: #{ENV["ATTIO_REDIRECT_URI"].sub("/callback", "") if ENV["ATTIO_REDIRECT_URI"]}"
  puts
  puts "Make sure you have set up:"
  puts "1. ATTIO_CLIENT_ID and ATTIO_CLIENT_SECRET in .env"
  puts "2. Redirect URIs in Attio app settings:"
  puts "   - http://localhost:4567/callback"
  puts "   - https://landscaping.ngrok.dev/callback (if using ngrok)"
  puts

  # Run Sinatra
  OAuthApp.run!
end
