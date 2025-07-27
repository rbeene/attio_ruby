# frozen_string_literal: true

require "spec_helper"

RSpec.describe Attio::Task do
  let(:task_id) { "test-task-id" }
  let(:task_data) do
    {
      id: {
        workspace_id: "test-workspace",
        task_id: task_id
      },
      content_plaintext: "Complete the integration",
      deadline_at: "2024-12-31T23:59:59Z",
      is_completed: false,
      linked_records: [
        {
          target_object: "people",
          target_record_id: "test-record-id"
        }
      ],
      assignees: [
        {
          referenced_actor_type: "workspace-member",
          referenced_actor_id: "test-member-id"
        }
      ],
      created_by_actor: {
        type: "workspace-member",
        id: "test-creator-id"
      },
      created_at: "2024-01-01T00:00:00Z"
    }
  end

  describe ".list" do
    let(:response) do
      {
        "data" => [task_data],
        "has_more" => false
      }
    end

    before do
      allow(Attio::Task).to receive(:execute_request).and_return(response)
    end

    it "sends a GET request to the correct endpoint" do
      expect(Attio::Task).to receive(:execute_request).with(
        :GET,
        "tasks",
        {},
        {}
      )

      Attio::Task.list
    end

    it "returns a ListObject" do
      result = Attio::Task.list
      expect(result).to be_a(Attio::APIResource::ListObject)
      expect(result.data.first).to be_a(Attio::Task)
    end

    it "accepts query parameters" do
      query_params = {
        limit: 10,
        offset: 0,
        linked_object: "people",
        linked_record_id: "test-record",
        assignee: "test-member",
        is_completed: false,
        sort: "created_at:desc"
      }

      expect(Attio::Task).to receive(:execute_request).with(
        :GET,
        "tasks",
        query_params,
        {}
      )

      Attio::Task.list(**query_params)
    end
  end

  describe ".create" do
    let(:create_params) do
      {
        content: "New task content",
        format: "plaintext",
        deadline_at: "2024-12-31T23:59:59Z",
        is_completed: false,
        linked_records: [
          {
            target_object: "people",
            target_record_id: "test-record-id"
          }
        ],
        assignees: [
          {
            referenced_actor_type: "workspace-member",
            referenced_actor_id: "test-member-id"
          }
        ]
      }
    end

    let(:response) do
      {
        "data" => task_data
      }
    end

    before do
      allow(Attio::Task).to receive(:execute_request).and_return(response)
    end

    it "sends a POST request with the correct data structure" do
      expect(Attio::Task).to receive(:execute_request).with(
        :POST,
        "tasks",
        { data: create_params },
        {}
      )

      Attio::Task.create(**create_params)
    end

    it "returns a Task instance" do
      result = Attio::Task.create(**create_params)
      expect(result).to be_a(Attio::Task)
      expect(result.content_plaintext).to eq("Complete the integration")
    end

    it "requires content parameter" do
      create_params.delete(:content)
      expect { Attio::Task.create(**create_params) }.to raise_error(ArgumentError, "Content is required")
    end
  end

  describe ".retrieve" do
    let(:response) do
      {
        "data" => task_data
      }
    end

    before do
      allow(Attio::Task).to receive(:execute_request).and_return(response)
    end

    it "sends a GET request to the correct endpoint" do
      expect(Attio::Task).to receive(:execute_request).with(
        :GET,
        "tasks/#{task_id}",
        {},
        {}
      )

      Attio::Task.retrieve(task_id)
    end

    it "returns a Task instance" do
      result = Attio::Task.retrieve(task_id)
      expect(result).to be_a(Attio::Task)
      expect(result.id).to eq(task_data[:id])
    end

    it "requires task_id" do
      expect { Attio::Task.retrieve(nil) }.to raise_error(ArgumentError, "ID is required")
    end
  end

  describe ".update" do
    let(:update_params) do
      {
        content: "Updated task content",
        is_completed: true,
        deadline_at: "2025-01-01T00:00:00Z"
      }
    end

    let(:response) do
      {
        "data" => task_data.merge(
          content_plaintext: "Updated task content",
          is_completed: true
        )
      }
    end

    before do
      allow(Attio::Task).to receive(:execute_request).and_return(response)
    end

    it "sends a PATCH request with the correct data" do
      expect(Attio::Task).to receive(:execute_request).with(
        :PATCH,
        "tasks/#{task_id}",
        { data: update_params },
        {}
      )

      Attio::Task.update(task_id, **update_params)
    end

    it "returns an updated Task instance" do
      result = Attio::Task.update(task_id, **update_params)
      expect(result).to be_a(Attio::Task)
      expect(result.is_completed).to eq(true)
    end
  end

  describe ".delete" do
    before do
      allow(Attio::Task).to receive(:execute_request).and_return({})
    end

    it "sends a DELETE request to the correct endpoint" do
      expect(Attio::Task).to receive(:execute_request).with(
        :DELETE,
        "tasks/#{task_id}",
        {},
        {}
      )

      Attio::Task.delete(task_id)
    end

    it "returns true on success" do
      result = Attio::Task.delete(task_id)
      expect(result).to eq(true)
    end
  end

  describe "instance methods" do
    let(:task) { Attio::Task.new(task_data) }

    describe "#content_plaintext" do
      it "returns the task content" do
        expect(task.content_plaintext).to eq("Complete the integration")
      end
    end

    describe "#deadline_at" do
      it "returns the deadline as a Time object" do
        expect(task.deadline_at).to be_a(Time)
        expect(task.deadline_at.iso8601).to eq("2024-12-31T23:59:59Z")
      end
    end

    describe "#is_completed" do
      it "returns the completion status" do
        expect(task.is_completed).to eq(false)
      end
    end

    describe "#linked_records" do
      it "returns the linked records array" do
        expect(task.linked_records).to be_an(Array)
        expect(task.linked_records.first[:target_object]).to eq("people")
      end
    end

    describe "#assignees" do
      it "returns the assignees array" do
        expect(task.assignees).to be_an(Array)
        expect(task.assignees.first[:referenced_actor_id]).to eq("test-member-id")
      end
    end

    describe "#created_by_actor" do
      it "returns the creator information" do
        expect(task.created_by_actor).to be_a(Hash)
        expect(task.created_by_actor[:type]).to eq("workspace-member")
      end
    end

    describe "#complete!" do
      before do
        allow(Attio::Task).to receive(:execute_request).and_return(
          "data" => task_data.merge(is_completed: true)
        )
      end

      it "marks the task as completed" do
        expect(Attio::Task).to receive(:execute_request).with(
          :PATCH,
          "tasks/#{task_id}",
          { data: { is_completed: true } },
          {}
        )

        result = task.complete!
        expect(result.is_completed).to eq(true)
      end
    end

    describe "#save" do
      before do
        task.is_completed = true
        allow(Attio::Task).to receive(:execute_request).and_return(
          "data" => task_data.merge(is_completed: true)
        )
      end

      it "updates the task with changed values" do
        expect(Attio::Task).to receive(:execute_request).with(
          :PATCH,
          "tasks/#{task_id}",
          { data: { is_completed: true } },
          {}
        )

        task.save
      end
    end

    describe "#destroy" do
      before do
        allow(Attio::Task).to receive(:execute_request).and_return({})
      end

      it "deletes the task" do
        expect(Attio::Task).to receive(:execute_request).with(
          :DELETE,
          "tasks/#{task_id}",
          {},
          {}
        )

        expect(task.destroy).to eq(true)
      end
    end
  end
end