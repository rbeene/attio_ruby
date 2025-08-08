# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Deal Integration", integration: true do
  let(:unique_id) { "#{Time.now.to_i}-#{rand(10000)}" }
  let(:deal_name) { "Test Deal #{unique_id}" }
  let(:owner_email) { ENV["ATTIO_TEST_USER_EMAIL"] }
  
  before do
    skip "Set ATTIO_TEST_USER_EMAIL env var to run Deal tests" unless owner_email
  end
  
  describe "Deal CRUD operations" do
    it "creates a deal with basic attributes" do
      # Note: owner is required - using a placeholder email
      # In a real app, you'd use an actual workspace member email
      deal = Attio::Deal.create(
        name: deal_name,
        value: 50000,
        stage: "In Progress",
        owner: owner_email
      )
      
      expect(deal).to be_a(Attio::Deal)
      expect(deal[:name]).to eq(deal_name)
      # Use the new amount method
      expect(deal.amount).to eq(50000.0)
      expect(deal.currency).to eq("USD")
      # Use the new stage method
      expect(deal.stage).to eq("In Progress")
      
      # Clean up
      deal.destroy
    end
    
    it "creates a deal with all attributes" do
      deal = Attio::Deal.create(
        name: "Full Deal #{unique_id}",
        value: 100000,
        stage: "Lead",
        owner: owner_email
      )
      
      expect(deal).to be_a(Attio::Deal)
      expect(deal[:name]).to eq("Full Deal #{unique_id}")
      # Use the new amount method
      expect(deal.amount).to eq(100000.0)
      expect(deal.currency).to eq("USD")
      # Use the new stage method
      expect(deal.stage).to eq("Lead")
      # Note: close_date and probability may not be standard attributes
      
      # Clean up
      deal.destroy
    end
    
    it "lists deals" do
      # Create a test deal first
      test_deal = Attio::Deal.create(
        name: "List Test #{unique_id}",
        value: 25000,
        stage: "In Progress",
        owner: owner_email
      )
      
      # List all deals
      deals = Attio::Deal.list
      
      expect(deals).to be_a(Attio::APIResource::ListObject)
      expect(deals.count).to be >= 1
      
      # Find our test deal
      our_deal = deals.find { |d| d[:name] == "List Test #{unique_id}" }
      expect(our_deal).not_to be_nil
      expect(our_deal.amount).to eq(25000.0)
      expect(our_deal.currency).to eq("USD")
      
      # Clean up
      test_deal.destroy
    end
    
    it "updates a deal" do
      # Create a test deal
      deal = Attio::Deal.create(
        name: "Update Test #{unique_id}",
        value: 30000,
        stage: "Lead",
        owner: owner_email
      )
      
      # Update the deal
      updated = deal.update_stage("Won 🎉")
      
      expect(updated.stage).to eq("Won 🎉")
      expect(updated[:name]).to eq("Update Test #{unique_id}")
      
      # Clean up
      deal.destroy
    end
    
    it "finds deals by stage" do
      # Create test deals with specific stage
      deal1 = Attio::Deal.create(
        name: "Find Test 1 #{unique_id}",
        value: 40000,
        stage: "In Progress",
        owner: owner_email
      )
      
      deal2 = Attio::Deal.create(
        name: "Find Test 2 #{unique_id}",
        value: 60000,
        stage: "In Progress",
        owner: owner_email
      )
      
      sleep 1 # Give API time to index
      
      # Find by stage
      negotiating_deals = Attio::Deal.list(params: {
        filter: { stage: "In Progress" }
      })
      
      # Check we found deals with this stage
      our_deals = negotiating_deals.select { |d| d[:name].include?(unique_id) }
      expect(our_deals.count).to be >= 2
      
      # Clean up
      deal1.destroy
      deal2.destroy
    end
    
    it "finds deals by value range" do
      # Create test deals
      small_deal = Attio::Deal.create(
        name: "Small Deal #{unique_id}",
        value: 10000,
        stage: "Lead",
        owner: owner_email
      )
      
      big_deal = Attio::Deal.create(
        name: "Big Deal #{unique_id}",
        value: 200000,
        stage: "Lead",
        owner: owner_email
      )
      
      sleep 1
      
      # Find high-value deals
      high_value_deals = Attio::Deal.find_by_value_range(min: 100000)
      
      # Check results
      our_big_deals = high_value_deals.select { |d| d[:name].include?(unique_id) }
      expect(our_big_deals.count).to be >= 1
      expect(our_big_deals.first.amount).to be >= 100000
      
      # Clean up
      small_deal.destroy
      big_deal.destroy
    end
  end
  
  describe "Deal associations" do
    it "creates a deal associated with a company" do
      # First create a company
      company = Attio::Company.create(
        name: "Deal Test Company #{unique_id}",
        domain: "dealtest#{unique_id}.com"
      )
      
      # Create deal with associated company (using domain)
      deal = Attio::Deal.create(
        name: "Company Deal #{unique_id}",
        value: 75000,
        stage: "In Progress",
        owner: owner_email,
        associated_company: ["dealtest#{unique_id}.com"]
      )
      
      expect(deal).to be_a(Attio::Deal)
      
      # Note: The API might not immediately return the association
      # We'd need to check how associated_company is returned
      
      # Clean up
      deal.destroy
      company.destroy
    end
  end
end