# frozen_string_literal: true

require_relative "base"
require_relative "../api_operations/list"
require_relative "../api_operations/retrieve"
require_relative "../api_operations/create"
require_relative "../api_operations/delete"

module Attio
  class Note < Resources::Base
    include APIOperations::List
    include APIOperations::Retrieve
    include APIOperations::Create
    include APIOperations::Delete

    def self.resource_path
      "/notes"
    end

    attr_reader :parent_object, :parent_record_id, :content, :format,
                :created_by_actor, :content_plaintext

    def initialize(attributes = {}, opts = {})
      super
      @parent_object = attributes[:parent_object] || attributes["parent_object"]
      @parent_record_id = attributes[:parent_record_id] || attributes["parent_record_id"]
      @content = attributes[:content] || attributes["content"]
      @format = attributes[:format] || attributes["format"] || "plaintext"
      @created_by_actor = attributes[:created_by_actor] || attributes["created_by_actor"]
      @content_plaintext = attributes[:content_plaintext] || attributes["content_plaintext"]
    end

    # Get the parent record
    def parent_record(opts = {})
      return nil unless parent_object && parent_record_id
      
      Record.retrieve(
        object: parent_object,
        record_id: parent_record_id,
        opts: opts
      )
    end

    # Check if note is in HTML format
    def html?
      format == "html"
    end

    # Check if note is in plaintext format
    def plaintext?
      format == "plaintext"
    end

    # Get plaintext version of content
    def to_plaintext
      content_plaintext || strip_html(content)
    end

    def to_h
      super.merge(
        parent_object: parent_object,
        parent_record_id: parent_record_id,
        content: content,
        format: format,
        created_by_actor: created_by_actor,
        content_plaintext: content_plaintext
      ).compact
    end

    class << self
      # List notes for a specific record
      def list(parent_object: nil, parent_record_id: nil, params = {}, opts = {})
        query_params = params.dup
        query_params[:parent_object] = parent_object if parent_object
        query_params[:parent_record_id] = parent_record_id if parent_record_id
        
        request = RequestBuilder.build(
          method: :GET,
          path: resource_path,
          params: query_params,
          headers: opts[:headers] || {},
          api_key: opts[:api_key]
        )
        
        response = connection_manager.execute(request)
        parsed = ResponseParser.parse(response, request)
        
        APIOperations::List::ListObject.new(parsed, self, query_params, opts)
      end

      # Create a note
      def create(parent_object:, parent_record_id:, content:, format: "plaintext", opts: {})
        validate_parent!(parent_object, parent_record_id)
        validate_content!(content)
        validate_format!(format)
        
        params = {
          parent_object: parent_object,
          parent_record_id: parent_record_id,
          content: content,
          format: format
        }
        
        request = RequestBuilder.build(
          method: :POST,
          path: resource_path,
          params: params,
          headers: opts[:headers] || {},
          api_key: opts[:api_key]
        )
        
        response = connection_manager.execute(request)
        parsed = ResponseParser.parse(response, request)
        
        new(parsed, opts)
      end

      # Get notes for a record
      def for_record(object:, record_id:, params = {}, opts = {})
        list(
          parent_object: object,
          parent_record_id: record_id,
          params: params,
          opts: opts
        )
      end

      private

      def validate_parent!(parent_object, parent_record_id)
        if parent_object.nil? || parent_object.to_s.empty?
          raise ArgumentError, "parent_object is required"
        end
        
        if parent_record_id.nil? || parent_record_id.to_s.empty?
          raise ArgumentError, "parent_record_id is required"
        end
      end

      def validate_content!(content)
        if content.nil? || content.to_s.strip.empty?
          raise ArgumentError, "content cannot be empty"
        end
      end

      def validate_format!(format)
        valid_formats = %w[plaintext html]
        unless valid_formats.include?(format.to_s)
          raise ArgumentError, "Invalid format: #{format}. Valid formats: #{valid_formats.join(', ')}"
        end
      end
    end

    # Instance methods

    # Notes cannot be updated
    def save(*)
      raise NotImplementedError, "Notes cannot be updated. Create a new note instead."
    end

    def update(*)
      raise NotImplementedError, "Notes cannot be updated. Create a new note instead."
    end

    private

    def strip_html(html)
      return html unless html.is_a?(String)
      
      # Basic HTML stripping (production apps should use a proper HTML parser)
      html.gsub(/<[^>]+>/, " ")
          .gsub(/\s+/, " ")
          .strip
    end
  end
end