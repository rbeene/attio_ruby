# frozen_string_literal: true

require "spec_helper"

RSpec.describe Attio::Thread do
  let(:thread_id) { "test-thread-id" }
  let(:thread_data) do
    {
      id: {
        workspace_id: "test-workspace",
        thread_id: thread_id
      },
      comments: [
        {
          id: {
            workspace_id: "test-workspace",
            comment_id: "test-comment-1"
          },
          thread_id: thread_id,
          content_plaintext: "First comment",
          entry: nil,
          record: {
            record_id: "test-record-id",
            object_id: "test-object-id"
          },
          resolved_at: nil,
          resolved_by: nil,
          created_at: "2024-01-01T00:00:00Z",
          author: {
            type: "workspace-member",
            id: "test-author-id"
          }
        }
      ],
      created_at: "2024-01-01T00:00:00Z"
    }
  end

  describe ".list" do
    let(:response) do
      {
        "data" => [thread_data],
        "has_more" => false
      }
    end

    before do
      allow(described_class).to receive(:execute_request).and_return(response)
    end

    it "sends a GET request to the correct endpoint" do
      expect(described_class).to receive(:execute_request).with(
        :GET,
        "threads",
        {},
        {}
      )

      described_class.list
    end

    it "returns a ListObject" do
      result = described_class.list
      expect(result).to be_a(Attio::APIResource::ListObject)
      expect(result.data.first).to be_a(described_class)
    end

    it "accepts query parameters for filtering by record" do
      query_params = {
        record_id: "test-record-id",
        object: "people",
        limit: 10,
        offset: 0
      }

      expect(described_class).to receive(:execute_request).with(
        :GET,
        "threads",
        query_params,
        {}
      )

      described_class.list(**query_params)
    end

    it "accepts query parameters for filtering by entry" do
      query_params = {
        entry_id: "test-entry-id",
        list: "test-list",
        limit: 10,
        offset: 0
      }

      expect(described_class).to receive(:execute_request).with(
        :GET,
        "threads",
        query_params,
        {}
      )

      described_class.list(**query_params)
    end
  end

  describe ".retrieve" do
    let(:response) do
      {
        "data" => thread_data
      }
    end

    before do
      allow(described_class).to receive(:execute_request).and_return(response)
    end

    it "sends a GET request to the correct endpoint" do
      expect(described_class).to receive(:execute_request).with(
        :GET,
        "threads/#{thread_id}",
        {},
        {}
      )

      described_class.retrieve(thread_id)
    end

    it "returns a Thread instance" do
      result = described_class.retrieve(thread_id)
      expect(result).to be_a(described_class)
      expect(result.id).to eq(thread_data[:id])
    end

    it "requires thread_id" do
      expect { described_class.retrieve(nil) }.to raise_error(ArgumentError, "ID is required")
    end
  end

  describe "instance methods" do
    let(:thread) { described_class.new(thread_data) }

    describe "#comments" do
      it "returns the comments array" do
        expect(thread.comments).to be_an(Array)
        expect(thread.comments.length).to eq(1)
        expect(thread.comments.first).to be_a(Hash)
      end

      it "provides access to comment data" do
        comment = thread.comments.first
        expect(comment[:content_plaintext]).to eq("First comment")
        expect(comment[:thread_id]).to eq(thread_id)
      end
    end

    describe "#comment_count" do
      it "returns the number of comments" do
        expect(thread.comment_count).to eq(1)
      end
    end

    describe "#has_comments?" do
      it "returns true when thread has comments" do
        expect(thread.has_comments?).to be(true)
      end

      it "returns false when thread has no comments" do
        empty_thread = described_class.new(thread_data.merge(comments: []))
        expect(empty_thread.has_comments?).to be(false)
      end
    end

    describe "#first_comment" do
      it "returns the first comment" do
        expect(thread.first_comment).to eq(thread.comments.first)
      end

      it "returns nil for empty thread" do
        empty_thread = described_class.new(thread_data.merge(comments: []))
        expect(empty_thread.first_comment).to be_nil
      end
    end

    describe "#last_comment" do
      it "returns the last comment" do
        expect(thread.last_comment).to eq(thread.comments.last)
      end

      it "returns nil for empty thread" do
        empty_thread = described_class.new(thread_data.merge(comments: []))
        expect(empty_thread.last_comment).to be_nil
      end
    end

    describe "#immutable?" do
      it "returns true since threads are read-only" do
        expect(thread.immutable?).to be(true)
      end
    end

    describe "#save" do
      it "raises an error since threads are read-only" do
        expect { thread.save }.to raise_error(Attio::InvalidRequestError, "Threads are read-only and cannot be modified")
      end
    end

    describe "#destroy" do
      it "raises an error since threads are read-only" do
        expect { thread.destroy }.to raise_error(Attio::InvalidRequestError, "Threads are read-only and cannot be deleted")
      end
    end
  end
end
