# frozen_string_literal: true

require_relative "../api_resource"

module Attio
  class Comment < APIResource
    # Comments only support create, retrieve, and delete (no list or update)
    api_operations :retrieve, :delete

    def self.resource_path
      "comments"
    end

    # Custom create implementation
    def self.create(content: nil, format: "plaintext", author: nil, thread_id: nil, created_at: nil, **opts)
      raise ArgumentError, "Content is required" if content.nil? || content.to_s.empty?
      raise ArgumentError, "Thread ID is required" if thread_id.nil? || thread_id.to_s.empty?
      raise ArgumentError, "Author is required" if author.nil?

      request_params = {
        data: {
          format: format,
          content: content,
          author: author,
          thread_id: thread_id
        }
      }

      # Only add created_at if provided
      request_params[:data][:created_at] = created_at if created_at

      response = execute_request(:POST, resource_path, request_params, opts)
      new(response["data"] || response, opts)
    end

    # Define attribute accessors
    attr_attio :content_plaintext, :thread_id, :author, :record, :entry, :resolved_by

    # Parse resolved_at as Time
    def resolved_at
      value = @attributes[:resolved_at]
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

    # Comments are immutable
    def immutable?
      true
    end

    # Override save to raise error since comments are immutable
    def save(**opts)
      raise InvalidRequestError, "Comments are immutable and cannot be updated"
    end

    # Override destroy to use the correct comment ID
    def destroy(**opts)
      raise InvalidRequestError, "Cannot destroy a comment without an ID" unless persisted?

      comment_id = extract_comment_id
      self.class.send(:execute_request, :DELETE, "#{self.class.resource_path}/#{comment_id}", {}, opts)
      @attributes.clear
      @changed_attributes.clear
      @id = nil
      true
    end

    private

    def extract_comment_id
      case id
      when Hash
        id[:comment_id] || id["comment_id"]
      else
        id
      end
    end

    def resource_path
      comment_id = extract_comment_id
      "#{self.class.resource_path}/#{comment_id}"
    end

    def to_h
      {
        id: id,
        thread_id: thread_id,
        content_plaintext: content_plaintext,
        entry: entry,
        record: record,
        resolved_at: resolved_at&.iso8601,
        resolved_by: resolved_by,
        created_at: created_at&.iso8601,
        author: author
      }.compact
    end

    def inspect
      "#<#{self.class.name}:#{object_id} id=#{id.inspect} thread=#{thread_id} content=#{content_plaintext&.truncate(30).inspect}>"
    end
  end
end
