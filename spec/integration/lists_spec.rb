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
      VCR.use_cassette("lists/create") do
        list = Attio::List.create(
          name: list_name,
          object: "people"
        )

        expect(list).to be_a(Attio::List)
        expect(list.name).to eq(list_name)
        expect(list.object).to eq("people")
        expect(list.id).to be_present
      end
    end

    it "retrieves a list" do
      VCR.use_cassette("lists/retrieve") do
        # Create list
        created = Attio::List.create(name: list_name, object: "people")

        # Retrieve it
        list = Attio::List.retrieve(created.id)

        expect(list.id).to eq(created.id)
        expect(list.name).to eq(list_name)
      end
    end

    it "lists all lists" do
      VCR.use_cassette("lists/list_all") do
        # Create a list first
        Attio::List.create(name: list_name, object: "people")

        # List all
        lists = Attio::List.list

        expect(lists).to be_a(Attio::APIOperations::List::ListObject)
        expect(lists.count).to be > 0

        list_names = lists.map(&:name)
        expect(list_names).to include(list_name)
      end
    end

    it "updates a list" do
      VCR.use_cassette("lists/update") do
        # Create list
        list = Attio::List.create(name: list_name, object: "people")

        # Update
        list.name = "Updated #{list_name}"
        list.save

        # Verify
        updated = Attio::List.retrieve(list.id)
        expect(updated.name).to eq("Updated #{list_name}")
      end
    end

    it "deletes a list" do
      VCR.use_cassette("lists/delete") do
        # Create list
        list = Attio::List.create(name: list_name, object: "people")

        # Delete
        result = list.destroy
        expect(result).to be true
        expect(list).to be_frozen

        # Verify deletion
        expect {
          Attio::List.retrieve(list.id)
        }.to raise_error(Attio::Errors::NotFoundError)
      end
    end
  end

  describe "list entries" do
    let(:list) { Attio::List.create(name: "Entry Test List", object: "people") }
    let(:person) do
      Attio::Record.create(
        object: "people",
        values: {
          name: "List Entry Test Person",
          email_addresses: "list-entry@example.com"
        }
      )
    end

    before do
      VCR.use_cassette("lists/setup_entries") do
        list
        person
      end
    end

    it "adds a record to a list" do
      VCR.use_cassette("lists/add_entry") do
        entry = list.add_record(person.id)

        expect(entry).to be_a(Attio::ListEntry)
        expect(entry.record_id).to eq(person.id)
        expect(entry.list_id).to eq(list.id)
      end
    end

    it "lists entries in a list" do
      VCR.use_cassette("lists/list_entries") do
        # Add entry
        list.add_record(person.id)

        # List entries
        entries = list.entries

        expect(entries).to be_a(Attio::APIOperations::List::ListObject)
        expect(entries.count).to be >= 1

        entry = entries.find { |e| e.record_id == person.id }
        expect(entry).to be_present
      end
    end

    it "removes a record from a list" do
      VCR.use_cassette("lists/remove_entry") do
        # Add entry
        list.add_record(person.id)

        # Remove entry
        result = list.remove_record(person.id)
        expect(result).to be true

        # Verify removal
        entries = list.entries
        expect(entries.none? { |e| e.record_id == person.id }).to be true
      end
    end

    it "handles duplicate entries" do
      VCR.use_cassette("lists/duplicate_entry") do
        # Add entry
        list.add_record(person.id)

        # Try to add again
        expect {
          list.add_record(person.id)
        }.to raise_error(Attio::Errors::InvalidRequestError)
      end
    end
  end

  describe "list with filters" do
    it "creates a smart list with filters" do
      VCR.use_cassette("lists/create_with_filters") do
        list = Attio::List.create(
          name: "VIP Customers",
          object: "people",
          filters: {
            job_title: {"$contains": "CEO"}
          }
        )

        expect(list.filters).to be_present
        expect(list.filters["job_title"]).to eq({"$contains" => "CEO"})
      end
    end
  end

  describe "batch operations" do
    let(:list) { Attio::List.create(name: "Batch Test List", object: "people") }
    let(:people) do
      Array.new(3) do |i|
        Attio::Record.create(
          object: "people",
          values: {
            name: "Batch Person #{i}",
            email_addresses: "batch#{i}@example.com"
          }
        )
      end
    end

    before do
      VCR.use_cassette("lists/setup_batch") do
        list
        people
      end
    end

    it "adds multiple records in batch" do
      VCR.use_cassette("lists/batch_add") do
        record_ids = people.map(&:id)

        entries = list.add_records(record_ids)

        expect(entries).to be_an(Array)
        expect(entries.size).to eq(3)
        expect(entries.all?(Attio::ListEntry)).to be true
      end
    end

    it "removes multiple records in batch" do
      VCR.use_cassette("lists/batch_remove") do
        # Add records first
        record_ids = people.map(&:id)
        list.add_records(record_ids)

        # Remove in batch
        result = list.remove_records(record_ids)
        expect(result).to be true

        # Verify all removed
        entries = list.entries
        expect(entries.count).to eq(0)
      end
    end
  end

  describe "error handling" do
    it "handles invalid object type" do
      VCR.use_cassette("lists/invalid_object") do
        expect {
          Attio::List.create(
            name: "Invalid List",
            object: "invalid_object"
          )
        }.to raise_error(Attio::Errors::InvalidRequestError)
      end
    end

    it "handles adding non-existent record" do
      VCR.use_cassette("lists/add_invalid_record") do
        list = Attio::List.create(name: "Error Test List", object: "people")

        expect {
          list.add_record("non-existent-record-id")
        }.to raise_error(Attio::Errors::NotFoundError)
      end
    end
  end
end
