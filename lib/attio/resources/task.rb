# frozen_string_literal: true

require_relative "../api_resource"

module Attio
  class Task < APIResource
    # Don't use api_operations for list since we need custom handling
    api_operations :create, :retrieve, :update, :delete

    def self.resource_path
      "tasks"
    end

    # Custom list implementation to handle query params properly
    def self.list(**params)
      # Query params should be part of the request, not opts
      query_params = params.slice(:limit, :offset, :sort, :linked_object, :linked_record_id, :assignee, :is_completed)
      opts = params.except(:limit, :offset, :sort, :linked_object, :linked_record_id, :assignee, :is_completed)

      response = execute_request(:GET, resource_path, query_params, opts)
      ListObject.new(response, self, params, opts)
    end

    class << self
      alias_method :all, :list
    end

    # Override create to handle required content parameter
    def self.create(content: nil, format: "plaintext", **params)
      raise ArgumentError, "Content is required" if content.nil? || content.to_s.empty?

      request_params = {
        data: {
          content: content,
          format: format,
          is_completed: params[:is_completed] || false,
          linked_records: params[:linked_records] || [],
          assignees: params[:assignees] || []
        }
      }

      # Only add optional fields if provided
      request_params[:data][:deadline_at] = params[:deadline_at] if params[:deadline_at]

      # Remove the params that we've already included in request_params
      opts = params.except(:content, :format, :deadline_at, :is_completed, :linked_records, :assignees)

      response = execute_request(:POST, resource_path, request_params, opts)
      new(response["data"] || response, opts)
    end

    # Override update to use PATCH with data wrapper
    def self.update(id, **params)
      validate_id!(id)

      request_params = {
        data: params.slice(:content, :format, :deadline_at, :is_completed, :linked_records, :assignees).compact
      }

      # Remove the params that we've already included in request_params
      opts = params.except(:content, :format, :deadline_at, :is_completed, :linked_records, :assignees)

      response = execute_request(:PATCH, "#{resource_path}/#{id}", request_params, opts)
      new(response["data"] || response, opts)
    end

    # Define attribute accessors
    attr_attio :content_plaintext, :is_completed, :linked_records, :assignees, :created_by_actor

    # Parse deadline_at as Time
    def deadline_at
      value = @attributes[:deadline_at]
      return nil if value.nil?

      case value
      when Time
        value
      when String
        Time.parse(value)
      else
        value
      end
    end

    # Convenience method to mark task as completed
    def complete!(**opts)
      raise InvalidRequestError, "Cannot complete a task without an ID" unless persisted?

      params = {
        data: {
          is_completed: true
        }
      }

      response = self.class.send(:execute_request, :PATCH, resource_path, params, opts)
      update_from(response["data"] || response)
      self
    end

    # Override save to handle task-specific attributes
    def save(**opts)
      raise InvalidRequestError, "Cannot save a task without an ID" unless persisted?

      params = {
        data: changed_attributes.slice(:content, :deadline_at, :is_completed, :linked_records, :assignees).compact
      }

      return self unless params[:data].any?

      response = self.class.send(:execute_request, :PATCH, resource_path, params, opts)
      update_from(response["data"] || response)
      reset_changes!
      self
    end

    # Override destroy to use the correct task ID
    def destroy(**opts)
      raise InvalidRequestError, "Cannot destroy a task without an ID" unless persisted?

      task_id = extract_task_id
      self.class.send(:execute_request, :DELETE, "#{self.class.resource_path}/#{task_id}", {}, opts)
      @attributes.clear
      @changed_attributes.clear
      @id = nil
      true
    end

    private

    def extract_task_id
      case id
      when Hash
        id[:task_id] || id["task_id"]
      else
        id
      end
    end

    def resource_path
      task_id = extract_task_id
      "#{self.class.resource_path}/#{task_id}"
    end
  end
end
