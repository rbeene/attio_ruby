# frozen_string_literal: true

require "spec_helper"

RSpec.describe Attio::Note do
  let(:note_attributes) do
    {
      id: {note_id: "note_123"},
      parent_object: "people",
      parent_record_id: "rec_123",
      title: "Meeting Notes",
      content_plaintext: "Discussed project timeline",
      content_markdown: "# Meeting Notes\n\nDiscussed project timeline",
      format: "markdown",
      tags: ["meeting", "project"],
      metadata: {priority: "high"},
      created_by_actor: {
        type: "user",
        id: "usr_123"
      }
    }
  end

  describe "#initialize" do
    it "sets attributes correctly" do
      note = described_class.new(note_attributes)

      expect(note.parent_object).to eq("people")
      expect(note.parent_record_id).to eq("rec_123")
      expect(note.title).to eq("Meeting Notes")
      expect(note.content_plaintext).to eq("Discussed project timeline")
      expect(note.content_markdown).to eq("# Meeting Notes\n\nDiscussed project timeline")
      expect(note.format).to eq("markdown")
      expect(note.tags).to eq(["meeting", "project"])
      expect(note.metadata).to eq({priority: "high"})
      expect(note.created_by_actor).to eq({type: "user", id: "usr_123"})
    end

    it "handles string keys" do
      string_attrs = {
        "id" => {"note_id" => "note_456"},
        "parent_object" => "companies",
        "parent_record_id" => "rec_456",
        "title" => "Company Notes"
      }

      note = described_class.new(string_attrs)
      expect(note.parent_object).to eq("companies")
      expect(note.parent_record_id).to eq("rec_456")
      expect(note.title).to eq("Company Notes")
    end

    it "defaults format to plaintext" do
      note = described_class.new({})
      expect(note.format).to eq("plaintext")
    end

    it "defaults tags to empty array" do
      note = described_class.new({})
      expect(note.tags).to eq([])
    end

    it "defaults metadata to empty hash" do
      note = described_class.new({})
      expect(note.metadata).to eq({})
    end
  end

  describe "#content" do
    it "returns plaintext content for plaintext format" do
      note = described_class.new(format: "plaintext", content_plaintext: "Plain text")
      expect(note.content).to eq("Plain text")
    end

    it "returns markdown content for markdown format" do
      note = described_class.new(format: "markdown", content_markdown: "# Markdown")
      expect(note.content).to eq("# Markdown")
    end

    it "returns markdown content for html format" do
      note = described_class.new(format: "html", content_markdown: "<h1>HTML</h1>")
      expect(note.content).to eq("<h1>HTML</h1>")
    end

    it "defaults to plaintext for unknown format" do
      note = described_class.new(format: "unknown", content_plaintext: "Fallback")
      expect(note.content).to eq("Fallback")
    end
  end

  describe "#created_by" do
    it "aliases created_by_actor" do
      note = described_class.new(note_attributes)
      expect(note.created_by).to eq(note.created_by_actor)
    end
  end

  describe "#parent_record" do
    let(:note) { described_class.new(note_attributes) }
    # Access the private constant within the test
    let(:internal_record) { Attio.const_get(:Internal)::Record }

    it "retrieves the parent record" do
      expect(internal_record).to receive(:retrieve).with(
        object: "people",
        record_id: "rec_123"
      )

      note.parent_record
    end

    it "returns nil when parent_object is missing" do
      note = described_class.new(parent_record_id: "rec_123")
      expect(note.parent_record).to be_nil
    end

    it "returns nil when parent_record_id is missing" do
      note = described_class.new(parent_object: "people")
      expect(note.parent_record).to be_nil
    end

    it "passes additional options" do
      expect(internal_record).to receive(:retrieve).with(
        object: "people",
        record_id: "rec_123",
        api_key: "custom_key"
      )

      note.parent_record(api_key: "custom_key")
    end
  end

  describe "#html?" do
    it "returns true for html format" do
      note = described_class.new(format: "html")
      expect(note.html?).to be true
    end

    it "returns false for other formats" do
      note = described_class.new(format: "plaintext")
      expect(note.html?).to be false
    end
  end

  describe "#plaintext?" do
    it "returns true for plaintext format" do
      note = described_class.new(format: "plaintext")
      expect(note.plaintext?).to be true
    end

    it "returns false for other formats" do
      note = described_class.new(format: "html")
      expect(note.plaintext?).to be false
    end
  end

  describe "#to_plaintext" do
    it "returns content_plaintext when available" do
      note = described_class.new(content_plaintext: "Plain text")
      expect(note.to_plaintext).to eq("Plain text")
    end

    it "strips HTML when content_plaintext is nil" do
      note = described_class.new(
        content_plaintext: nil,
        content_markdown: "<p>Hello <strong>world</strong></p>"
      )
      expect(note.to_plaintext).to eq("Hello world")
    end

    it "handles complex HTML" do
      note = described_class.new(
        content_plaintext: nil,
        format: "html",
        content_markdown: "<div><p>Line 1</p><p>Line 2</p></div>"
      )
      expect(note.to_plaintext).to eq("Line 1 Line 2")
    end
  end

  describe "#resource_path" do
    it "returns the correct path for a persisted note" do
      note = described_class.new(note_attributes)
      expect(note.resource_path).to eq("notes/note_123")
    end

    it "extracts note_id from nested hash" do
      note = described_class.new(id: {note_id: "note_789"})
      expect(note.resource_path).to eq("notes/note_789")
    end

    it "handles simple ID format" do
      note = described_class.new(id: "note_simple")
      expect(note.resource_path).to eq("notes/note_simple")
    end

    it "raises error for unpersisted note" do
      note = described_class.new({})
      expect { note.resource_path }.to raise_error(
        Attio::InvalidRequestError,
        "Cannot generate path without an ID"
      )
    end
  end

  describe "#destroy" do
    it "calls delete with extracted note_id" do
      note = described_class.new(note_attributes)

      expect(described_class).to receive(:delete).with("note_123")
      expect(note.destroy).to be true
      expect(note).to be_frozen
    end

    it "handles simple ID format" do
      note = described_class.new(id: "simple_id")

      expect(described_class).to receive(:delete).with("simple_id")
      note.destroy
    end

    it "raises error for unpersisted note" do
      note = described_class.new({})
      expect { note.destroy }.to raise_error(
        Attio::InvalidRequestError,
        "Cannot destroy a note without an ID"
      )
    end

    it "passes options to delete" do
      note = described_class.new(note_attributes)

      expect(described_class).to receive(:delete).with("note_123", api_key: "custom_key")
      note.destroy(api_key: "custom_key")
    end
  end

  describe "#save" do
    it "raises NotImplementedError" do
      note = described_class.new(note_attributes)
      expect { note.save }.to raise_error(
        NotImplementedError,
        "Notes cannot be updated. Create a new note instead."
      )
    end
  end

  describe "#update" do
    it "raises NotImplementedError" do
      note = described_class.new(note_attributes)
      expect { note.update }.to raise_error(
        NotImplementedError,
        "Notes cannot be updated. Create a new note instead."
      )
    end
  end

  describe "#to_h" do
    it "includes all note attributes" do
      note = described_class.new(note_attributes)
      hash = note.to_h

      expect(hash).to include(
        parent_object: "people",
        parent_record_id: "rec_123",
        content: "# Meeting Notes\n\nDiscussed project timeline",
        format: "markdown",
        created_by_actor: {type: "user", id: "usr_123"},
        content_plaintext: "Discussed project timeline"
      )
    end

    it "compacts nil values" do
      note = described_class.new({})
      hash = note.to_h

      expect(hash).not_to have_key(:parent_object)
      expect(hash).not_to have_key(:parent_record_id)
    end
  end

  describe ".retrieve" do
    it "extracts note_id from nested hash" do
      allow(described_class).to receive(:execute_request).with(
        :GET,
        "notes/note_123",
        {},
        {}
      ).and_return({"data" => note_attributes})

      note = described_class.retrieve({note_id: "note_123"})
      expect(note).to be_a(described_class)
    end

    it "handles simple ID format" do
      allow(described_class).to receive(:execute_request).with(
        :GET,
        "notes/simple_id",
        {},
        {}
      ).and_return({"data" => {}})

      result = described_class.retrieve("simple_id")
      expect(result).to be_a(described_class)
    end

    it "validates ID" do
      expect { described_class.retrieve(nil) }.to raise_error(ArgumentError)
    end
  end

  describe ".create" do
    it "creates a note with required parameters" do
      allow(described_class).to receive(:execute_request).with(
        :POST,
        "notes",
        {
          data: {
            title: "Test Note",
            parent_object: "people",
            parent_record_id: "rec_123",
            content: "Note content",
            format: "plaintext"
          }
        },
        {}
      ).and_return({"data" => note_attributes})

      note = described_class.create(
        object: "people",
        record_id: "rec_123",
        content: "Note content",
        title: "Test Note"
      )
      expect(note).to be_a(described_class)
    end

    it "handles parent_object/parent_record_id parameters" do
      allow(described_class).to receive(:execute_request).with(
        :POST,
        "notes",
        {
          data: {
            title: "Content",
            parent_object: "companies",
            parent_record_id: "rec_456",
            content: "Content",
            format: "plaintext"
          }
        },
        {}
      ).and_return({"data" => {}})

      result = described_class.create(
        parent_object: "companies",
        parent_record_id: "rec_456",
        content: "Content"
      )
      expect(result).to be_a(described_class)
    end

    it "uses content as title if title not provided" do
      expect(described_class).to receive(:execute_request) do |_, _, params, _|
        expect(params[:data][:title]).to eq("Note content")
        {"data" => {}}
      end

      described_class.create(
        object: "people",
        record_id: "rec_123",
        content: "Note content"
      )
    end

    it "validates parent object" do
      expect {
        described_class.create(record_id: "rec_123", content: "Content")
      }.to raise_error(ArgumentError, "parent_object is required")
    end

    it "validates parent record ID" do
      expect {
        described_class.create(object: "people", content: "Content")
      }.to raise_error(ArgumentError, "parent_record_id is required")
    end

    it "validates content" do
      expect {
        described_class.create(object: "people", record_id: "rec_123", content: "")
      }.to raise_error(ArgumentError, "content cannot be empty")

      expect {
        described_class.create(object: "people", record_id: "rec_123", content: "   ")
      }.to raise_error(ArgumentError, "content cannot be empty")
    end

    it "validates format" do
      expect {
        described_class.create(
          object: "people",
          record_id: "rec_123",
          content: "Content",
          format: "invalid"
        )
      }.to raise_error(ArgumentError, "Invalid format: invalid. Valid formats: plaintext, html")
    end

    it "handles custom API key" do
      allow(described_class).to receive(:execute_request).with(
        :POST,
        "notes",
        anything,
        {api_key: "custom_key"}
      ).and_return({"data" => {}})

      result = described_class.create(
        object: "people",
        record_id: "rec_123",
        content: "Content",
        api_key: "custom_key"
      )
      expect(result).to be_a(described_class)
    end
  end

  describe ".for_record" do
    it "lists notes for a specific record" do
      expect(described_class).to receive(:list).with(
        {parent_object: "people", parent_record_id: "rec_123"}
      )

      described_class.for_record(object: "people", record_id: "rec_123")
    end

    it "merges additional parameters" do
      expect(described_class).to receive(:list).with(
        {limit: 10, parent_object: "companies", parent_record_id: "rec_456"},
        api_key: "custom_key"
      )

      described_class.for_record(
        {limit: 10},
        object: "companies",
        record_id: "rec_456",
        api_key: "custom_key"
      )
    end
  end

  describe "API operations" do
    it "provides list operation" do
      expect(described_class).to respond_to(:list)
    end

    it "provides retrieve operation" do
      expect(described_class).to respond_to(:retrieve)
    end

    it "provides create operation" do
      expect(described_class).to respond_to(:create)
    end

    it "provides delete operation" do
      expect(described_class).to respond_to(:delete)
    end

    it "does not provide update operation" do
      expect(described_class).not_to respond_to(:update)
    end
  end
end
