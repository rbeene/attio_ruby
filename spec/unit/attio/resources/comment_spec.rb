# frozen_string_literal: true

require "spec_helper"

RSpec.describe Attio::Comment do
  let(:comment_id) { "test-comment-id" }
  let(:thread_id) { "test-thread-id" }
  let(:comment_data) do
    {
      id: {
        workspace_id: "test-workspace",
        comment_id: comment_id
      },
      thread_id: thread_id,
      content_plaintext: "This is a test comment",
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
  end

  describe ".create" do
    let(:create_params) do
      {
        format: "plaintext",
        content: "New comment content",
        author: {
          type: "workspace-member",
          id: "test-author-id"
        },
        thread_id: thread_id
      }
    end

    let(:response) do
      {
        "data" => comment_data
      }
    end

    before do
      allow(described_class).to receive(:execute_request).and_return(response)
    end

    it "sends a POST request with the correct data structure" do
      expect(described_class).to receive(:execute_request).with(
        :POST,
        "comments",
        {data: create_params},
        {}
      )

      described_class.create(**create_params)
    end

    it "returns a Comment instance" do
      result = described_class.create(**create_params)
      expect(result).to be_a(described_class)
      expect(result.content_plaintext).to eq("This is a test comment")
    end

    it "requires content parameter" do
      create_params.delete(:content)
      expect { described_class.create(**create_params) }.to raise_error(ArgumentError, "Content is required")
    end

    it "requires thread_id parameter" do
      create_params.delete(:thread_id)
      expect { described_class.create(**create_params) }.to raise_error(ArgumentError, "Thread ID is required")
    end

    it "requires author parameter" do
      create_params.delete(:author)
      expect { described_class.create(**create_params) }.to raise_error(ArgumentError, "Author is required")
    end

    it "allows created_at to be specified" do
      create_params[:created_at] = "2024-06-01T12:00:00Z"

      expect(described_class).to receive(:execute_request).with(
        :POST,
        "comments",
        {data: create_params},
        {}
      )

      described_class.create(**create_params)
    end
  end

  describe ".retrieve" do
    let(:response) do
      {
        "data" => comment_data
      }
    end

    before do
      allow(described_class).to receive(:execute_request).and_return(response)
    end

    it "sends a GET request to the correct endpoint" do
      expect(described_class).to receive(:execute_request).with(
        :GET,
        "comments/#{comment_id}",
        {},
        {}
      )

      described_class.retrieve(comment_id)
    end

    it "returns a Comment instance" do
      result = described_class.retrieve(comment_id)
      expect(result).to be_a(described_class)
      expect(result.id).to eq(comment_data[:id])
    end

    it "requires comment_id" do
      expect { described_class.retrieve(nil) }.to raise_error(ArgumentError, "ID is required")
    end
  end

  describe ".delete" do
    before do
      allow(described_class).to receive(:execute_request).and_return({})
    end

    it "sends a DELETE request to the correct endpoint" do
      expect(described_class).to receive(:execute_request).with(
        :DELETE,
        "comments/#{comment_id}",
        {},
        {}
      )

      described_class.delete(comment_id)
    end

    it "returns true on success" do
      result = described_class.delete(comment_id)
      expect(result).to be(true)
    end

    it "requires comment_id" do
      expect { described_class.delete(nil) }.to raise_error(ArgumentError, "ID is required")
    end
  end

  describe "instance methods" do
    let(:comment) { described_class.new(comment_data) }

    describe "#content_plaintext" do
      it "returns the comment content" do
        expect(comment.content_plaintext).to eq("This is a test comment")
      end
    end

    describe "#thread_id" do
      it "returns the thread ID" do
        expect(comment.thread_id).to eq(thread_id)
      end
    end

    describe "#author" do
      it "returns the author information" do
        expect(comment.author).to be_a(Hash)
        expect(comment.author[:type]).to eq("workspace-member")
        expect(comment.author[:id]).to eq("test-author-id")
      end
    end

    describe "#record" do
      it "returns the associated record" do
        expect(comment.record).to be_a(Hash)
        expect(comment.record[:record_id]).to eq("test-record-id")
      end
    end

    describe "#entry" do
      it "returns the associated entry" do
        expect(comment.entry).to be_nil
      end
    end

    describe "#resolved_at" do
      it "returns nil when not resolved" do
        expect(comment.resolved_at).to be_nil
      end

      it "returns a Time object when resolved" do
        comment_with_resolution = described_class.new(
          comment_data.merge(resolved_at: "2024-01-02T00:00:00Z")
        )
        expect(comment_with_resolution.resolved_at).to be_a(Time)
      end
    end

    describe "#resolved_by" do
      it "returns the resolver information when resolved" do
        comment_with_resolution = described_class.new(
          comment_data.merge(
            resolved_by: {type: "workspace-member", id: "resolver-id"}
          )
        )
        expect(comment_with_resolution.resolved_by).to be_a(Hash)
        expect(comment_with_resolution.resolved_by[:id]).to eq("resolver-id")
      end
    end

    describe "#destroy" do
      before do
        allow(described_class).to receive(:execute_request).and_return({})
      end

      it "deletes the comment" do
        expect(described_class).to receive(:execute_request).with(
          :DELETE,
          "comments/#{comment_id}",
          {},
          {}
        )

        expect(comment.destroy).to be(true)
      end
    end

    describe "#immutable?" do
      it "returns true since comments are immutable" do
        expect(comment.immutable?).to be(true)
      end
    end

    describe "#save" do
      it "raises an error since comments are immutable" do
        expect { comment.save }.to raise_error(Attio::InvalidRequestError, "Comments are immutable and cannot be updated")
      end
    end
  end
end
