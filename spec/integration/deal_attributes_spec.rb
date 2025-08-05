# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Deal Attributes", integration: true do
  it "lists all deal attributes" do
    attributes = Attio::Attribute.for_object("deals")
    
    puts "\n=== Deal Attributes ==="
    attributes.each do |attr|
      puts "Slug: #{attr[:slug]}"
      puts "  Name: #{attr[:name]}"
      puts "  Type: #{attr[:type]}"
      puts "  API Slug: #{attr[:api_slug]}"
      
      # If it's a select attribute, show the options
      if attr[:type] == "select" && attr[:options]
        puts "  Options:"
        attr[:options].each do |option|
          puts "    - #{option["title"]} (ID: #{option["id"]})"
        end
      end
      
      puts "---"
    end
    
    expect(attributes).not_to be_empty
  end
  
  it "checks deal object configuration" do
    deal_object = Attio::Object.retrieve("deals")
    
    puts "\n=== Deal Object ==="
    puts "Name: #{deal_object[:name]}"
    puts "API Slug: #{deal_object[:api_slug]}"
    puts "Singular: #{deal_object[:singular_noun]}"
    puts "Plural: #{deal_object[:plural_noun]}"
    
    expect(deal_object).not_to be_nil
  end
end