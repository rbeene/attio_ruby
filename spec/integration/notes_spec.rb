# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Notes Integration", :integration do
  before do
    Attio.configure do |config|
      config.api_key = ENV["ATTIO_API_KEY"]
    end
    person
    company
  end

  let(:person) do
    Attio::Record.create(
      object: "people",
      values: {
        name: [{
          first_name: "Note",
          last_name: "Test Person",
          full_name: "Note Test Person"
        }],
        email_addresses: ["notes-#{SecureRandom.hex(8)}@example.com"]
      }
    )
  end

  let(:company) do
    Attio::Record.create(
      object: "companies",
      values: {
        name: "Note Test Company",
        domains: ["notetest-#{SecureRandom.hex(8)}.com"]
      }
    )
  end

  describe "creating notes" do
    let(:note_params) do
      {
        parent_object: "people",
        parent_record_id: person.id.is_a?(Hash) ? person.id["record_id"] : person.id,
        content: "Had a great meeting with this person. They're interested in our product.",
        format: "plaintext"
      }
    end

    it "creates a note successfully" do
      note = Attio::Note.create(**note_params)
      expect(note).to be_a(Attio::Note)
    end

    it "preserves the note content" do
      note = Attio::Note.create(**note_params)
      expect(note.content_plaintext).to include("great meeting")
    end

    it "sets the correct format" do
      note = Attio::Note.create(**note_params)
      expect(note.format).to eq("plaintext")
    end

    it "maintains parent relationship" do
      note = Attio::Note.create(**note_params)
      expect(note.parent_object).to eq("people")
      expect(note.parent_record_id).to eq(person.id.is_a?(Hash) ? person.id["record_id"] : person.id)
    end

    it "assigns system fields" do
      note = Attio::Note.create(**note_params)
      expect(note.id).to be_truthy
      expect(note.created_at).to be_truthy
    end

    it "creates a markdown note on a company" do
      markdown_content = <<~MD
        ## Meeting Notes
        
        **Date**: 2024-01-15
        **Attendees**: John Doe, Jane Smith
        
        ### Key Points:
        - Discussed partnership opportunities
        - Budget range: $50k-$100k
        - Decision timeline: Q2 2024
        
        ### Next Steps:
        1. Send proposal by end of week
        2. Schedule follow-up call
        3. Prepare demo
      MD

      note = Attio::Note.create(
        parent_object: "companies",
        parent_record_id: company.id.is_a?(Hash) ? company.id["record_id"] : company.id,
        content: markdown_content,
        format: "markdown"
      )

      expect(note.format).to eq("markdown")
      expect(note.content).to include("## Meeting Notes")
      expect(note.content).to include("Budget range")
    end

    it "creates a note with custom title" do
      note = Attio::Note.create(
        parent_object: "people",
        parent_record_id: person.id.is_a?(Hash) ? person.id["record_id"] : person.id,
        title: "Initial Contact",
        content: "Reached out via LinkedIn. Scheduled intro call for next week.",
        format: "plaintext"
      )

      expect(note.title).to eq("Initial Contact")
    end
  end

  describe "listing notes" do
    before do
      # Create multiple notes
      3.times do |i|
        Attio::Note.create(
          parent_object: "people",
          parent_record_id: person.id.is_a?(Hash) ? person.id["record_id"] : person.id,
          content: "Note #{i + 1}: Test content",
          format: "plaintext"
        )
      end
    end

    it "lists notes for a record" do
      notes = Attio::Note.list(
        parent_object: "people",
        parent_record_id: person.id
      )

      expect(notes).to be_a(Attio::APIResource::ListObject)
      expect(notes.count).to be >= 3
      expect(notes.all? { |n| n.parent_record_id == person.id }).to be true
    end

    it "lists all notes with pagination" do
      notes = Attio::Note.list(params: {limit: 2})

      expect(notes.count).to eq(2)

      if notes.has_next_page?
        next_page = notes.next_page
        expect(next_page).to be_a(Attio::APIResource::ListObject)
      end
    end

    it "filters notes by date range" do
      # Get notes created in the last hour
      recent_notes = Attio::Note.list(
        params: {
          filter: {
            created_at: {"$gte": (Time.now - 3600).iso8601}
          }
        }
      )

      expect(recent_notes.all? { |n|
        Time.parse(n.created_at) >= (Time.now - 3600)
      }).to be true
    end
  end

  describe "retrieving notes" do
    let(:note) do
      Attio::Note.create(
        parent_object: "people",
        parent_record_id: person.id.is_a?(Hash) ? person.id["record_id"] : person.id,
        content: "Test note for retrieval",
        format: "plaintext"
      )
    end

    before do
      note
    end

    it "retrieves a specific note" do
      retrieved = Attio::Note.retrieve(note.id)

      expect(retrieved.id).to eq(note.id)
      expect(retrieved.content_plaintext).to eq("Test note for retrieval")
    end

    it "includes creator information" do
      retrieved = Attio::Note.retrieve(note.id)

      expect(retrieved.created_by_actor).to be_truthy
      expect(retrieved.created_by[:type]).to eq("workspace-member")
      expect(retrieved.created_by[:id]).to be_present
    end
  end

  describe "updating notes" do
    let(:note) do
      Attio::Note.create(
        parent_object: "people",
        parent_record_id: person.id.is_a?(Hash) ? person.id["record_id"] : person.id,
        content: "Original content",
        format: "plaintext"
      )
    end

    before do
      note
    end

    it "updates note content" do
      # Notes are immutable - cannot update content directly
      note.save

      # Verify update
      updated = Attio::Note.retrieve(note.id)
      expect(updated.content).to eq("Updated content with new information")
    end

    it "changes note format" do
      # Notes are immutable - cannot update format directly
      note.content = "# Updated as Markdown\n\nNow with **formatting**!"
      note.save

      updated = Attio::Note.retrieve(note.id)
      expect(updated.format).to eq("markdown")
      expect(updated.content).to include("# Updated as Markdown")
    end
  end

  describe "deleting notes" do
    let(:note) do
      Attio::Note.create(
        parent_object: "people",
        parent_record_id: person.id.is_a?(Hash) ? person.id["record_id"] : person.id,
        content: "Note to be deleted",
        format: "plaintext"
      )
    end

    before do
      note
    end

    it "deletes a note" do
      result = note.destroy
      expect(result).to be true
      expect(note).to be_frozen

      # Verify deletion
      expect {
        Attio::Note.retrieve(note.id)
      }.to raise_error(Attio::NotFoundError)
    end
  end

  describe "note attachments" do
    it "creates a note with attachments metadata" do
      note = Attio::Note.create(
        parent_object: "companies",
        parent_record_id: company.id.is_a?(Hash) ? company.id["record_id"] : company.id,
        content: "Please see attached proposal document",
        format: "plaintext",
        metadata: {
          attachments: [
            {
              name: "proposal.pdf",
              size: 1024000,
              type: "application/pdf"
            }
          ]
        }
      )

      expect(note.metadata).to be_truthy
      expect(note.metadata["attachments"]).to be_an(Array)
    end
  end

  describe "bulk note operations" do
    it "creates multiple notes efficiently" do
      notes_data = Array.new(5) do |i|
        {
          parent_object: "people",
          parent_record_id: person.id.is_a?(Hash) ? person.id["record_id"] : person.id,
          content: "Bulk note #{i + 1}: Important information",
          format: "plaintext"
        }
      end

      notes = notes_data.map { |data| Attio::Note.create(**data) }

      expect(notes.size).to eq(5)
      expect(notes.all?(Attio::Note)).to be true
    end
  end

  describe "error handling" do
    it "handles invalid parent object" do
      expect {
        Attio::Note.create(
          parent_object: "invalid_object",
          parent_record_id: "some_id",
          content: "Test",
          format: "plaintext"
        )
      }.to raise_error(Attio::BadRequestError)
    end

    it "handles non-existent parent record" do
      expect {
        Attio::Note.create(
          parent_object: "people",
          parent_record_id: "non_existent_id",
          content: "Test",
          format: "plaintext"
        )
      }.to raise_error(Attio::BadRequestError)
    end

    it "handles invalid format" do
      expect {
        Attio::Note.create(
          parent_object: "people",
          parent_record_id: person.id.is_a?(Hash) ? person.id["record_id"] : person.id,
          content: "Test",
          format: "invalid_format"
        )
      }.to raise_error(ArgumentError)
    end
  end
end
