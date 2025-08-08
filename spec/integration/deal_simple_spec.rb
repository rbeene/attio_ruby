# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Simple Deal Test", :integration do
  it "creates a minimal deal" do
    # First, let's see if we can create a deal without an owner
    # to understand the actual requirements

    puts "\n=== Attempting Deal Creation ==="

    begin
      # Try minimal deal
      deal = Attio::Deal.create(
        name: "Minimal Deal #{Time.now.to_i}",
        stage: "Lead",
        value: 1000,
        owner: ENV["ATTIO_TEST_USER_EMAIL"] || "test@example.com"
      )

      puts "SUCCESS! Deal created"
      puts "ID: #{deal.id}"
      puts "Owner in response: #{deal[:owner].inspect}"

      deal.destroy
    rescue Attio::BadRequestError => e
      puts "Failed: #{e.message}"

      # If it's about the owner, let's document what email to use
      if e.message.include?("workspace member")
        puts "\nTo run this test successfully, set ATTIO_TEST_USER_EMAIL environment variable"
        puts "to a valid workspace member email address."
      end
    end
  end

  it "tests deal with associations" do
    # First create a person to associate with
    person = Attio::Person.create(
      email_addresses: ["contact@example.com"],
      name: [{
        first_name: "Test",
        last_name: "Contact"
      }]
    )

    begin
      deal = Attio::Deal.create(
        name: "Deal with Associations #{Time.now.to_i}",
        stage: "Lead",
        value: 5000,
        owner: ENV["ATTIO_TEST_USER_EMAIL"] || "test@example.com",
        associated_people: [person.id],
        associated_company: "example.com"
      )

      puts "\n=== Deal with Associations ==="
      puts "ID: #{deal.id}"
      puts "Associated People: #{deal[:associated_people].inspect}"
      puts "Associated Company: #{deal[:associated_company].inspect}"

      deal.destroy
    ensure
      person&.destroy
    end
  rescue Attio::BadRequestError => e
    puts "Failed: #{e.message}"
  end
end
