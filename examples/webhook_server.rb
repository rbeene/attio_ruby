#!/usr/bin/env ruby
# frozen_string_literal: true

require "bundler/setup"
require "attio"
require "sinatra"
require "json"
require "openssl"
require "dotenv/load"

# Webhook server example for Attio Ruby gem
# Demonstrates webhook creation, management, and event handling

Attio.configure do |config|
  config.api_key = ENV["ATTIO_API_KEY"]
end

# Store for webhook events (use Redis or database in production)
$webhook_events = []

# Webhook signature verification
def verify_webhook_signature(payload_body, signature_header)
  return false unless signature_header

  # Extract timestamp and signatures
  elements = signature_header.split(" ")
  timestamp = nil
  signatures = []

  elements.each do |element|
    key, value = element.split("=", 2)
    case key
    when "t"
      timestamp = value
    when "v1"
      signatures << value
    end
  end

  return false unless timestamp

  # Verify timestamp is recent (within 5 minutes)
  current_time = Time.now.to_i
  if (current_time - timestamp.to_i).abs > 300
    return false
  end

  # Compute expected signature
  signed_payload = "#{timestamp}.#{payload_body}"
  expected_signature = OpenSSL::HMAC.hexdigest(
    "SHA256",
    ENV["ATTIO_WEBHOOK_SECRET"] || "test_secret",
    signed_payload
  )

  # Check if computed signature matches any of the signatures
  signatures.any? { |sig| Rack::Utils.secure_compare(expected_signature, sig) }
end

# Webhook endpoint
post "/webhooks/attio" do
  # Get raw body for signature verification
  request.body.rewind
  payload_body = request.body.read

  # Verify webhook signature
  signature = request.env["HTTP_ATTIO_SIGNATURE"]

  unless verify_webhook_signature(payload_body, signature)
    halt 401, {error: "Invalid signature"}.to_json
  end

  # Parse webhook data
  begin
    webhook_data = JSON.parse(payload_body)
  rescue JSON::ParserError
    halt 400, {error: "Invalid JSON"}.to_json
  end

  # Store event
  event = {
    id: webhook_data["id"],
    type: webhook_data["type"],
    occurred_at: webhook_data["occurred_at"],
    data: webhook_data["data"],
    received_at: Time.now.iso8601
  }

  $webhook_events << event

  # Process webhook based on type
  case webhook_data["type"]
  when "record.created"
    process_record_created(webhook_data["data"])
  when "record.updated"
    process_record_updated(webhook_data["data"])
  when "record.deleted"
    process_record_deleted(webhook_data["data"])
  when "list_entry.created"
    process_list_entry_created(webhook_data["data"])
  when "note.created"
    process_note_created(webhook_data["data"])
  else
    puts "Unknown webhook type: #{webhook_data["type"]}"
  end

  # Return success
  status 200
  {received: true}.to_json
end

# Webhook event processors
# Process record.created webhook events
# @param data [Hash] Webhook event data
def process_record_created(data)
  puts "New #{data["object"]} created: #{data["record"]["id"]}"

  # Example: Send welcome email for new people
  if data["object"] == "people" && data["record"]["email_addresses"]
    puts "  Would send welcome email to: #{data["record"]["email_addresses"]}"
  end

  # Example: Enrich company data
  if data["object"] == "companies" && data["record"]["domains"]
    puts "  Would enrich company data for: #{data["record"]["domains"]}"
  end
end

# Process record.updated webhook events
# @param data [Hash] Webhook event data
def process_record_updated(data)
  puts "#{data["object"]} updated: #{data["record"]["id"]}"

  # Example: Sync changes to CRM
  changed_fields = data["changes"]&.keys || []
  if changed_fields.any?
    puts "  Changed fields: #{changed_fields.join(", ")}"
    puts "  Would sync to external CRM"
  end
end

# Process record.deleted webhook events
# @param data [Hash] Webhook event data
def process_record_deleted(data)
  puts "#{data["object"]} deleted: #{data["record_id"]}"

  # Example: Clean up related data
  puts "  Would clean up related data in external systems"
end

# Process list_entry.created webhook events
# @param data [Hash] Webhook event data
def process_list_entry_created(data)
  puts "Record added to list: #{data["list"]["name"]}"

  # Example: Trigger marketing automation
  if /leads|prospects/i.match?(data["list"]["name"])
    puts "  Would trigger marketing automation workflow"
  end
end

# Process note.created webhook events
# @param data [Hash] Webhook event data
def process_note_created(data)
  puts "New note created on #{data["parent_object"]}"

  # Example: Notify team members
  if /urgent|important|asap/i.match?(data["content"])
    puts "  Would notify team members of urgent note"
  end
end

# Webhook management endpoints
get "/" do
  <<~HTML
    <h1>Attio Webhook Server</h1>
    <p>Webhook endpoint: POST /webhooks/attio</p>
    <p>Events received: #{$webhook_events.size}</p>
    <hr>
    <a href="/webhooks">Manage Webhooks</a> |
    <a href="/events">View Events</a> |
    <a href="/test">Test Webhook</a>
  HTML
end

# List webhooks
get "/webhooks" do
  webhooks = Attio::Webhook.list

  html = "<h1>Configured Webhooks</h1>"
  html += "<a href='/webhooks/new'>Create New Webhook</a><br><br>"

  webhooks.each do |webhook|
    html += <<~HTML
      <div style="border: 1px solid #ccc; padding: 10px; margin: 10px 0;">
        <strong>#{webhook.name}</strong><br>
        URL: #{webhook.url}<br>
        Events: #{webhook.subscriptions.join(", ")}<br>
        Status: #{webhook.active ? "✅ Active" : "❌ Inactive"}<br>
        <a href="/webhooks/#{webhook.id}/test">Test</a> |
        <a href="/webhooks/#{webhook.id}/toggle">#{webhook.active ? "Disable" : "Enable"}</a> |
        <a href="/webhooks/#{webhook.id}/delete" onclick="return confirm('Delete webhook?')">Delete</a>
      </div>
    HTML
  end

  html += "<br><a href='/'>Back</a>"
  html
end

# Create webhook form
get "/webhooks/new" do
  <<~HTML
    <h1>Create Webhook</h1>
    <form method="post" action="/webhooks/create">
      <label>Name: <input name="name" value="Test Webhook" required></label><br><br>
      <label>URL: <input name="url" value="#{request.base_url}/webhooks/attio" required size="50"></label><br><br>
      
      <label>Events to subscribe:</label><br>
      <label><input type="checkbox" name="events[]" value="record.created" checked> record.created</label><br>
      <label><input type="checkbox" name="events[]" value="record.updated" checked> record.updated</label><br>
      <label><input type="checkbox" name="events[]" value="record.deleted"> record.deleted</label><br>
      <label><input type="checkbox" name="events[]" value="list_entry.created"> list_entry.created</label><br>
      <label><input type="checkbox" name="events[]" value="list_entry.deleted"> list_entry.deleted</label><br>
      <label><input type="checkbox" name="events[]" value="note.created"> note.created</label><br><br>
      
      <button type="submit">Create Webhook</button>
      <a href="/webhooks">Cancel</a>
    </form>
  HTML
end

# Create webhook
post "/webhooks/create" do
  Attio::Webhook.create(
    name: params[:name],
    url: params[:url],
    subscriptions: params[:events] || []
  )

  redirect "/webhooks"
rescue => e
  "Error creating webhook: #{e.message}"
end

# Test webhook
get "/webhooks/:id/test" do
  webhook = Attio::Webhook.retrieve(params[:id])

  # Trigger a test event
  test_data = {
    id: "test_#{SecureRandom.hex(8)}",
    type: "record.created",
    occurred_at: Time.now.iso8601,
    data: {
      object: "people",
      record: {
        id: "test_person_#{SecureRandom.hex(8)}",
        name: "Test Person",
        email_addresses: "test@example.com"
      }
    }
  }

  # In a real scenario, Attio would send this
  # For testing, we'll simulate it
  uri = URI(webhook.url)
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = uri.scheme == "https"

  request = Net::HTTP::Post.new(uri.path)
  request["Content-Type"] = "application/json"
  request["Attio-Signature"] = "t=#{Time.now.to_i} v1=test_signature"
  request.body = test_data.to_json

  response = http.request(request)

  <<~HTML
    <h1>Webhook Test Result</h1>
    <p>Webhook: #{webhook.name}</p>
    <p>URL: #{webhook.url}</p>
    <p>Response Status: #{response.code}</p>
    <p>Response Body: #{response.body}</p>
    <a href="/webhooks">Back to Webhooks</a>
  HTML
rescue => e
  "Error testing webhook: #{e.message}"
end

# Toggle webhook
get "/webhooks/:id/toggle" do
  webhook = Attio::Webhook.retrieve(params[:id])
  webhook.active = !webhook.active
  webhook.save

  redirect "/webhooks"
end

# Delete webhook
get "/webhooks/:id/delete" do
  Attio::Webhook.delete(params[:id])
  redirect "/webhooks"
end

# View events
get "/events" do
  html = "<h1>Webhook Events (#{$webhook_events.size})</h1>"

  if $webhook_events.empty?
    html += "<p>No events received yet.</p>"
  else
    html += "<table border='1' cellpadding='5'>"
    html += "<tr><th>Time</th><th>Type</th><th>Object</th><th>Data</th></tr>"

    $webhook_events.last(50).reverse_each do |event|
      html += <<~HTML
        <tr>
          <td>#{event[:received_at]}</td>
          <td>#{event[:type]}</td>
          <td>#{event[:data]["object"] if event[:data]}</td>
          <td><pre>#{JSON.pretty_generate(event[:data])}</pre></td>
        </tr>
      HTML
    end

    html += "</table>"
  end

  html += "<br><a href='/'>Back</a> | <a href='/events/clear'>Clear Events</a>"
  html
end

# Clear events
get "/events/clear" do
  $webhook_events.clear
  redirect "/events"
end

# Test webhook locally
get "/test" do
  <<~HTML
    <h1>Test Webhook Locally</h1>
    <button onclick="testCreate()">Test Create Event</button>
    <button onclick="testUpdate()">Test Update Event</button>
    <button onclick="testDelete()">Test Delete Event</button>
    <br><br>
    <div id="result"></div>
    <br>
    <a href="/">Back</a>
    
    <script>
      function sendTest(data) {
        fetch('/webhooks/attio', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'Attio-Signature': 't=' + Math.floor(Date.now()/1000) + ' v1=test'
          },
          body: JSON.stringify(data)
        })
        .then(r => r.json())
        .then(data => {
          document.getElementById('result').innerHTML = 
            '<pre>' + JSON.stringify(data, null, 2) + '</pre>';
        });
      }
      
      function testCreate() {
        sendTest({
          id: 'evt_' + Date.now(),
          type: 'record.created',
          occurred_at: new Date().toISOString(),
          data: {
            object: 'people',
            record: {
              id: 'person_test',
              name: 'Test Person',
              email_addresses: 'test@example.com'
            }
          }
        });
      }
      
      function testUpdate() {
        sendTest({
          id: 'evt_' + Date.now(),
          type: 'record.updated',
          occurred_at: new Date().toISOString(),
          data: {
            object: 'people',
            record: {
              id: 'person_test',
              name: 'Updated Person',
              email_addresses: 'updated@example.com'
            },
            changes: {
              name: { old: 'Test Person', new: 'Updated Person' }
            }
          }
        });
      }
      
      function testDelete() {
        sendTest({
          id: 'evt_' + Date.now(),
          type: 'record.deleted',
          occurred_at: new Date().toISOString(),
          data: {
            object: 'people',
            record_id: 'person_test'
          }
        });
      }
    </script>
  HTML
end

# Webhook statistics
get "/stats" do
  event_types = $webhook_events.group_by { |e| e[:type] }

  html = "<h1>Webhook Statistics</h1>"
  html += "<p>Total events: #{$webhook_events.size}</p>"

  html += "<h2>Events by Type</h2>"
  html += "<ul>"
  event_types.each do |type, events|
    html += "<li>#{type}: #{events.size}</li>"
  end
  html += "</ul>"

  html += "<h2>Recent Activity</h2>"
  html += "<ul>"
  $webhook_events.last(10).reverse_each do |event|
    html += "<li>#{event[:received_at]} - #{event[:type]}</li>"
  end
  html += "</ul>"

  html += "<br><a href='/'>Back</a>"
  html
end

# Run the server
if __FILE__ == $0
  puts "=== Attio Webhook Server Example ==="
  puts "Starting server on http://localhost:4568"
  puts
  puts "This example demonstrates:"
  puts "- Creating and managing webhooks"
  puts "- Receiving and processing webhook events"
  puts "- Signature verification"
  puts "- Event handling patterns"
  puts
  puts "Visit http://localhost:4568 to get started"
  puts

  # Configure Sinatra
  set :port, 4568
  set :bind, "0.0.0.0"

  # Run the server
  run!
end
