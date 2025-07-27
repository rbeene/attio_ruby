# frozen_string_literal: true

require_relative "../api_resource"

module Attio
  class Thread < APIResource
    # Threads only support list and retrieve (read-only resource)
    # Don't use api_operations for list since we need custom handling
    api_operations :retrieve

    def self.resource_path
      "threads"
    end

    # Custom list implementation to handle query params properly
    def self.list(**params)
      # Query params should be part of the request, not opts
      query_params = params.slice(:record_id, :object, :entry_id, :list, :limit, :offset)
      opts = params.except(:record_id, :object, :entry_id, :list, :limit, :offset)
      
      response = execute_request(:GET, resource_path, query_params, opts)
      ListObject.new(response, self, params, opts)
    end
    
    class << self
      alias_method :all, :list
    end

    # Define attribute accessors
    attr_attio :comments

    # Helper methods for working with comments
    def comment_count
      comments&.length || 0
    end

    def has_comments?
      comment_count > 0
    end

    def first_comment
      comments&.first
    end

    def last_comment
      comments&.last
    end

    # Threads are read-only
    def immutable?
      true
    end

    # Override save to raise error since threads are read-only
    def save(**opts)
      raise InvalidRequestError, "Threads are read-only and cannot be modified"
    end

    # Override destroy to raise error since threads are read-only
    def destroy(**opts)
      raise InvalidRequestError, "Threads are read-only and cannot be deleted"
    end

    private

    def extract_thread_id
      case id
      when Hash
        id[:thread_id] || id["thread_id"]
      else
        id
      end
    end

    def resource_path
      thread_id = extract_thread_id
      "#{self.class.resource_path}/#{thread_id}"
    end

    def to_h
      {
        id: id,
        comments: comments,
        created_at: created_at&.iso8601
      }.compact
    end

    def inspect
      "#<#{self.class.name}:#{object_id} id=#{id.inspect} comments=#{comment_count}>"
    end
  end
end