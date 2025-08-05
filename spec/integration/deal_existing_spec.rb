# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Existing Deals", integration: true do
  it "lists existing deals to understand structure" do
    deals = Attio::Deal.list(params: { limit: 5 })
    
    puts "\n=== Existing Deals ==="
    if deals.any?
      deals.each_with_index do |deal, i|
        puts "\nDeal #{i + 1}:"
        puts "  ID: #{deal.id}"
        puts "  Name: #{deal[:name]}"
        puts "  Stage: #{deal[:stage]}"
        puts "  Value: #{deal[:value]}"
        puts "  Owner: #{deal[:owner]}"
        puts "  Associated People: #{deal[:associated_people]}"
        puts "  Associated Company: #{deal[:associated_company]}"
        puts "  Lead Source: #{deal[:lead_source]}"
        puts "  Cancel Reason: #{deal[:cancel_reason]}"
        puts "  Raw values: #{deal.to_h[:values].keys}"
      end
    else
      puts "No existing deals found"
    end
    
    expect(deals).to be_a(Attio::APIResource::ListObject)
  end
end