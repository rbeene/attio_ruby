# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Find Required Deal Attributes", integration: true do
  it "finds attributes by their IDs" do
    attributes = Attio::Attribute.for_object("deals")
    
    puts "\n=== Looking for Required Attributes ==="
    
    # The IDs we're looking for
    required_ids = [
      "c154dc21-03b3-4488-a022-d03d05fc64c1",
      "e3cf8dd8-42ea-43c3-afad-d94b1f2e423b"
    ]
    
    attributes.each do |attr|
      # Check both id and slug fields
      attr_id = attr[:id] || attr[:slug]
      
      if required_ids.include?(attr_id)
        puts "\nFOUND REQUIRED ATTRIBUTE!"
        puts "  ID: #{attr_id}"
        puts "  Name: #{attr[:name]}"
        puts "  API Slug: #{attr[:api_slug]}"
        puts "  Type: #{attr[:type]}"
        puts "  Is Required: #{attr[:is_required]}"
        
        if attr[:type] == "select" && attr[:options]
          puts "  Options:"
          attr[:options].each do |option|
            puts "    - #{option["title"]} (ID: #{option["id"]})"
          end
        end
      end
    end
    
    # Also check if any attributes are marked as required
    puts "\n=== All Required Attributes ==="
    attributes.each do |attr|
      if attr[:is_required]
        puts "Required: #{attr[:name]} (#{attr[:api_slug]}) - Type: #{attr[:type]}"
      end
    end
  end
  
  it "tries to understand owner field better" do
    puts "\n=== Testing Owner Field ==="
    
    # First, let's try to get current workspace members
    begin
      puts "About to call WorkspaceMember.all..."
      members = Attio::WorkspaceMember.all
      puts "Successfully got members list"
      puts "\nWorkspace Members:"
      puts "Calling members.first(3)..."
      first_three = members.first(3)
      puts "Got first three members"
      first_three.each do |member|
        puts "  - #{member[:email_address]} (ID: #{member.id})"
      end
      
      if members.any?
        # Try creating a deal with a real member
        member_email = members.first[:email_address]
        puts "\nTrying to create deal with owner: #{member_email}"
        
        deal = Attio::Deal.create(
          name: "Owner Test #{Time.now.to_i}",
          stage: "Lead",
          value: 5000,
          owner: member_email
        )
        
        puts "SUCCESS! Created deal with owner"
        puts "  Deal ID: #{deal.id}"
        puts "  Owner in response: #{deal[:owner].inspect}"
        
        deal.destroy
      end
    rescue => e
      puts "Error: #{e.message}"
    end
  end
end