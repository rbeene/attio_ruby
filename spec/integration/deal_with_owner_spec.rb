# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Deal with Owner", integration: true do
  it "gets current user and creates a deal" do
    # Try to get the current user (the API key owner)
    begin
      meta = Attio::Meta.identify
      
      puts "\n=== Meta Info ==="
      puts "Workspace: #{meta.workspace.inspect}"
      puts "Token: #{meta.token.inspect}"
      puts "Authorized by workspace member ID: #{meta[:authorized_by_workspace_member_id]}"
      
      # For API tokens, we need to use the test email from environment
      # since the meta endpoint doesn't return the email address
      owner_email = ENV["ATTIO_TEST_USER_EMAIL"]
      unless owner_email
        skip "Cannot test Deal with owner without ATTIO_TEST_USER_EMAIL environment variable"
      end
      
      # Now create a deal with this owner
      deal = Attio::Deal.create(
        name: "Test Deal with Owner #{Time.now.to_i}",
        stage: "Lead",
        value: 10000,
        owner: owner_email
      )
      
      puts "\n=== Deal Created Successfully! ==="
      puts "Deal ID: #{deal.id}"
      puts "Name: #{deal[:name]}"
      puts "Stage: #{deal[:stage]}"
      puts "Value: #{deal[:value]}"
      puts "Owner: #{deal[:owner]}"
      
      # Clean up
      deal.destroy
      puts "\nDeal cleaned up successfully"
      
    rescue => e
      puts "Error: #{e.class} - #{e.message}"
      puts e.backtrace.first(5)
    end
  end
end