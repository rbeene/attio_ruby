# frozen_string_literal: true

require "spec_helper"

RSpec.describe "List Integration", :integration do
  before do
    Attio.configure do |config|
      config.api_key = ENV["ATTIO_API_KEY"]
    end
  end

  describe "list management" do
    let(:list_name) { "Test List #{SecureRandom.hex(4)}" }

    it "creates a list" do
      list = Attio::List.create(
        name: list_name,
        object: "people"
      )

      expect(list).to be_a(Attio::List)
      expect(list.name).to eq(list_name)
      expect(list.object).to eq("people")
      expect(list.id).to be_truthy
    end

    it "retrieves a list" do
      # Create list
      created = Attio::List.create(name: list_name, object: "people")

      # Retrieve it
      list = Attio::List.retrieve(created.id)

      expect(list.id).to eq(created.id)
      expect(list.name).to eq(list_name)
    end

    it "lists all lists" do
      # Create a list first
      Attio::List.create(name: list_name, object: "people")

      # List all
      lists = Attio::List.list

      expect(lists).to be_a(Attio::APIResource::ListObject)
      expect(lists.count).to be > 0

      list_names = lists.map(&:name)
      expect(list_names).to include(list_name)
    end

    it "updates a list" do
      # Create list
      list = Attio::List.create(name: list_name, object: "people")

      # Update
      list.name = "Updated #{list_name}"
      list.save

      # Verify
      updated = Attio::List.retrieve(list.id)
      expect(updated.name).to eq("Updated #{list_name}")
    end

    it "cannot delete a list" do
      # Create list
      list = Attio::List.create(name: list_name, object: "people")

      # Lists cannot be deleted via API
      expect {
        list.destroy
      }.to raise_error(NotImplementedError, "Lists cannot be deleted via the Attio API")
    end
  end

  describe "list entries" do
    let(:list) { Attio::List.create(name: "Entry Test List #{SecureRandom.hex(4)}", object: "people") }
    let(:person) do
      Attio::Record.create(
        object: "people",
        values: {
          name: [{
            first_name: "List",
            last_name: "Entry Test Person #{SecureRandom.hex(4)}",
            full_name: "List Entry Test Person #{SecureRandom.hex(4)}"
          }],
          email_addresses: ["list-entry-#{SecureRandom.hex(8)}@example.com"]
        }
      )
    end

    before do
      list
      person
    end

    it "adds a record to a list" do
      record_id = person.id.is_a?(Hash) ? person.id["record_id"] : person.id
      entry = list.add_record(record_id)

      expect(entry).to be_truthy
      expect(entry["parent_record_id"]).to eq(record_id)
      expect(entry["id"]["list_id"]).to eq(list.id["list_id"])
    end

    it "lists entries in a list" do
      # Add entry
      record_id = person.id.is_a?(Hash) ? person.id["record_id"] : person.id
      list.add_record(record_id)

      # List entries
      entries = list.entries

      expect(entries).to be_an(Array)
      expect(entries.count).to be >= 1

      entry = entries.find { |e| e["parent_record_id"] == record_id }
      expect(entry).to be_truthy
    end

    it "removes a record from a list" do
      # Add entry
      record_id = person.id.is_a?(Hash) ? person.id["record_id"] : person.id
      entry = list.add_record(record_id)

      # Remove entry by entry_id
      entry_id = entry["id"]["entry_id"]
      result = list.remove_record(entry_id)
      expect(result).to be_truthy

      # Verify removal
      entries = list.entries
      expect(entries.none? { |e| e["parent_record_id"] == record_id }).to be true
    end

    it "allows duplicate entries" do
      # Add entry
      record_id = person.id.is_a?(Hash) ? person.id["record_id"] : person.id
      entry1 = list.add_record(record_id)

      # Add again - should succeed
      entry2 = list.add_record(record_id)
      
      expect(entry1["id"]["entry_id"]).not_to eq(entry2["id"]["entry_id"])
      expect(entry1["parent_record_id"]).to eq(entry2["parent_record_id"])
    end
  end

  describe "list with filters" do
    it "creates a smart list with filters" do
      list = Attio::List.create(
        name: "VIP Customers #{SecureRandom.hex(4)}",
        object: "people",
        filters: {
          job_title: {"$contains": "CEO"}
        }
      )

      # The API accepts filters on creation but may not return them immediately
      expect(list.name).to include("VIP Customers")
      expect(list.object).to eq("people")
    end
  end


  describe "error handling" do
    it "handles invalid object type" do
      expect {
        Attio::List.create(
          name: "Invalid List",
          object: "invalid_object"
        )
      }.to raise_error(Attio::NotFoundError)
    end

    it "handles adding non-existent record" do
      list = Attio::List.create(name: "Error Test List #{SecureRandom.hex(4)}", object: "people")

      expect {
        list.add_record("non-existent-record-id")
      }.to raise_error(Attio::BadRequestError)
    end
  end
end
