# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Entry Integration", :integration do
  before do
    Attio.configure do |config|
      config.api_key = ENV["ATTIO_API_KEY"] || "5d4b3063a71a19b8d12a98f936b6b74d886d05f8580dba40538e019da8871eaf"
    end
  end

  let(:test_list_id) { "a1bd2c90-1c6d-4b1b-8c48-79ae46b5bc2c" } # Test API List
  let(:test_record_id) { "0174bfac-74b9-41de-b757-c6fa2a68ab00" } # Phone Test person

  describe "entries" do
    let(:entry_data) do
      {
        parent_record_id: test_record_id,
        parent_object: "people",
        entry_values: {} # This list doesn't have custom attributes
      }
    end

    it "creates an entry" do
      VCR.use_cassette("entries/create_entry") do
        entry = Attio::Entry.create(
          list: test_list_id,
          **entry_data
        )

        expect(entry).to be_a(Attio::Entry)
        expect(entry.parent_record_id).to eq(test_record_id)
        expect(entry.parent_object).to eq("people")
        expect(entry.id).to be_present
      end
    end

    it "lists entries for a list" do
      VCR.use_cassette("entries/list_entries") do
        entries = Attio::Entry.list(list: test_list_id, limit: 10)

        expect(entries).to be_a(Attio::APIResource::ListObject)
        expect(entries).to respond_to(:each)

        if entries.any?
          entry = entries.first
          expect(entry).to be_a(Attio::Entry)
          expect(entry.parent_record_id).to be_present
        end
      end
    end

    it "retrieves a specific entry" do
      VCR.use_cassette("entries/retrieve_entry") do
        # First create an entry
        created = Attio::Entry.create(list: test_list_id, **entry_data)

        # Then retrieve it
        entry = Attio::Entry.retrieve(
          list: test_list_id,
          entry_id: created.id[:entry_id]
        )

        expect(entry.id).to eq(created.id)
        expect(entry.parent_record_id).to eq(created.parent_record_id)
      end
    end

    it "updates an entry" do
      VCR.use_cassette("entries/update_entry") do
        # First create an entry
        created = Attio::Entry.create(list: test_list_id, **entry_data)

        # Then update it
        updated = Attio::Entry.update(
          list: test_list_id,
          entry_id: created.id[:entry_id],
          entry_values: {
            status: "completed",
            notes: "Updated via Ruby SDK"
          }
        )

        expect(updated.entry_values[:status]).to eq("completed")
        expect(updated.entry_values[:notes]).to eq("Updated via Ruby SDK")
      end
    end

    it "deletes an entry" do
      VCR.use_cassette("entries/delete_entry") do
        # First create an entry
        created = Attio::Entry.create(list: test_list_id, **entry_data)

        # Then delete it
        result = Attio::Entry.delete(
          list: test_list_id,
          entry_id: created.id[:entry_id]
        )

        expect(result).to be(true)

        # Verify it's deleted by trying to retrieve it
        expect {
          Attio::Entry.retrieve(
            list: test_list_id,
            entry_id: created.id[:entry_id]
          )
        }.to raise_error(Attio::NotFoundError)
      end
    end

    it "asserts an entry by parent" do
      VCR.use_cassette("entries/assert_by_parent") do
        entry = Attio::Entry.assert_by_parent(
          list: test_list_id,
          parent_record_id: test_record_id,
          parent_object: "people",
          entry_values: {
            status: "new",
            notes: "Created via assert"
          }
        )

        expect(entry).to be_a(Attio::Entry)
        expect(entry.parent_record_id).to eq(test_record_id)
        expect(entry.entry_values[:status]).to eq("new")
      end
    end

    describe "filtering and sorting" do
      it "filters entries by status" do
        VCR.use_cassette("entries/filter_by_status") do
          entries = Attio::Entry.list(
            list: test_list_id,
            filter: {status: "active"},
            limit: 5
          )

          entries.each do |entry|
            expect(entry.entry_values[:status]).to eq("active")
          end
        end
      end

      it "sorts entries by created date" do
        VCR.use_cassette("entries/sort_by_created") do
          entries = Attio::Entry.list(
            list: test_list_id,
            sorts: [{attribute: "created_at", direction: "desc"}],
            limit: 5
          )

          expect(entries).to be_a(Attio::APIResource::ListObject)
        end
      end
    end

    describe "instance methods" do
      it "saves changes to an entry" do
        VCR.use_cassette("entries/save_entry") do
          # First create an entry
          entry = Attio::Entry.create(list: test_list_id, **entry_data)

          # Modify and save
          entry.entry_values[:status] = "inactive"
          entry.save

          # Verify the change persisted
          retrieved = Attio::Entry.retrieve(
            list: test_list_id,
            entry_id: entry.id[:entry_id]
          )
          expect(retrieved.entry_values[:status]).to eq("inactive")
        end
      end

      it "destroys an entry instance" do
        VCR.use_cassette("entries/destroy_instance") do
          # First create an entry
          entry = Attio::Entry.create(list: test_list_id, **entry_data)
          entry_id = entry.id[:entry_id]

          # Destroy it
          result = entry.destroy
          expect(result).to be(true)

          # Verify it's deleted
          expect {
            Attio::Entry.retrieve(list: test_list_id, entry_id: entry_id)
          }.to raise_error(Attio::NotFoundError)
        end
      end
    end
  end
end
