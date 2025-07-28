# frozen_string_literal: true

require_relative "../api_resource"

module Attio
  class Task < APIResource
    # Don't use api_operations for list since we need custom handling
    api_operations :create, :retrieve, :update, :delete

    def self.resource_path
      "tasks"
    end

    # Override id_key to use task_id
    def self.id_key
      :task_id
    end

    # Custom list implementation to handle query params properly
    def self.list(**params)
      # Query params should be part of the request, not opts
      query_params = params.slice(:limit, :offset, :sort, :linked_object, :linked_record_id, :assignee, :is_completed)
      opts = params.except(:limit, :offset, :sort, :linked_object, :linked_record_id, :assignee, :is_completed)

      response = execute_request(HTTPMethods::GET, resource_path, query_params, opts)
      ListObject.new(response, self, params, opts)
    end

    class << self
      alias_method :all, :list
    end

    # Override create to handle required content parameter
    def self.create(content: nil, format: FormatTypes::PLAINTEXT, **params)
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

      response = execute_request(HTTPMethods::POST, resource_path, request_params, opts)
      new(response["data"] || response, opts)
    end

    # Override update to use PATCH with data wrapper
    def self.update(task_id:, **params)
      validate_id!(task_id)

      request_params = {
        data: params.slice(:content, :format, :deadline_at, :is_completed, :linked_records, :assignees).compact
      }

      # Remove the params that we've already included in request_params
      opts = params.except(:content, :format, :deadline_at, :is_completed, :linked_records, :assignees)

      path = Util::PathBuilder.build_resource_path(resource_path, task_id)
      response = execute_request(HTTPMethods::PATCH, path, request_params, opts)
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

      response = self.class.execute_request(HTTPMethods::PATCH, resource_path, params, opts)
      update_from(response["data"] || response)
      self
    end

    # Override save to handle task-specific attributes and support creation
    def save(**opts)
      if persisted?
        save_update(**opts)
      else
        save_create(**opts)
      end
    end

    protected

    def save_update(**opts)
      params = {
        data: changed_attributes.slice(:content, :deadline_at, :is_completed, :linked_records, :assignees).compact
      }

      return self unless params[:data].any?

      response = self.class.execute_request(HTTPMethods::PATCH, resource_path, params, opts)
      update_from(response["data"] || response)
      reset_changes!
      self
    end

    def save_create(**opts)
      # Task requires content at minimum
      unless self[:content]
        raise InvalidRequestError, "Cannot save a new task without 'content' attribute"
      end

      # Prepare all attributes for creation - only include non-nil values
      create_params = {
        content: self[:content],
        format: self[:format] || FormatTypes::PLAINTEXT
      }
      create_params[:deadline_at] = self[:deadline_at] if self[:deadline_at]
      create_params[:is_completed] = self[:is_completed] unless self[:is_completed].nil?
      create_params[:linked_records] = self[:linked_records] if self[:linked_records]
      create_params[:assignees] = self[:assignees] if self[:assignees]

      created = self.class.create(**create_params, **opts)

      if created
        @id = created.id
        @created_at = created.created_at
        update_from(created.instance_variable_get(:@attributes))
        reset_changes!
        self
      else
        raise InvalidRequestError, "Failed to create task"
      end
    end

    public

    # Override destroy to use the correct task ID
    def destroy(**opts)
      raise InvalidRequestError, "Cannot destroy a task without an ID" unless persisted?

      path = Util::PathBuilder.build_resource_path(self.class.resource_path, extract_id)
      self.class.execute_request(HTTPMethods::DELETE, path, {}, opts)
      @attributes.clear
      @changed_attributes.clear
      @id = nil
      true
    end
  end
end
