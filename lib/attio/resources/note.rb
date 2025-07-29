# frozen_string_literal: true

require_relative "../api_resource"

module Attio
  # Represents a note attached to a record in Attio
  class Note < APIResource
    api_operations :list, :retrieve, :create, :delete

    # API endpoint path for notes
    # @return [String] The API path
    def self.resource_path
      "notes"
    end

    # Read-only attributes - notes are immutable
    attr_reader :parent_object, :parent_record_id, :title, :format,
      :created_by_actor, :content_plaintext, :content_markdown, :tags, :metadata

    # Alias for compatibility
    alias_method :created_by, :created_by_actor

    # Convenience method to get content based on format
    def content
      case format
      when "plaintext"
        content_plaintext
      when "html", "markdown"
        content_markdown
      else
        content_plaintext
      end
    end

    def initialize(attributes = {}, opts = {})
      super
      normalized_attrs = normalize_attributes(attributes)
      @parent_object = normalized_attrs[:parent_object]
      @parent_record_id = normalized_attrs[:parent_record_id]
      @title = normalized_attrs[:title]
      @content_plaintext = normalized_attrs[:content_plaintext]
      @content_markdown = normalized_attrs[:content_markdown]
      @tags = normalized_attrs[:tags] || []
      @metadata = normalized_attrs[:metadata] || {}
      @format = normalized_attrs[:format] || "plaintext"
      @created_by_actor = normalized_attrs[:created_by_actor]
    end

    # Get the parent record
    def parent_record(**)
      return nil unless parent_object && parent_record_id

      Internal::Record.retrieve(
        object: parent_object,
        record_id: parent_record_id,
        **
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
      return content_plaintext if content_plaintext

      # If no plaintext, try to get markdown/html content and strip HTML
      html_content = content_markdown || content
      return nil unless html_content

      strip_html(html_content)
    end

    def resource_path
      raise InvalidRequestError, "Cannot generate path without an ID" unless persisted?
      note_id = id.is_a?(Hash) ? (id[:note_id] || id["note_id"]) : id
      "#{self.class.resource_path}/#{note_id}"
    end

    # Override destroy to handle nested ID
    def destroy(**opts)
      raise InvalidRequestError, "Cannot destroy a note without an ID" unless persisted?

      note_id = id.is_a?(Hash) ? (id[:note_id] || id["note_id"]) : id
      self.class.delete(note_id, **opts)
      freeze
      true
    end

    # Notes cannot be updated
    def save(*)
      raise NotImplementedError, "Notes cannot be updated. Create a new note instead."
    end

    def update(*)
      raise NotImplementedError, "Notes cannot be updated. Create a new note instead."
    end

    # Convert note to hash representation
    # @return [Hash] Note data as a hash
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
      # Override retrieve to handle nested ID
      def retrieve(id, **opts)
        note_id = id.is_a?(Hash) ? (id[:note_id] || id["note_id"]) : id
        validate_id!(note_id)
        response = execute_request(:GET, "#{resource_path}/#{note_id}", {}, opts)
        new(response["data"] || response, opts)
      end

      # Override create to handle validation and parameter mapping
      def create(**kwargs)
        # Extract options from kwargs
        opts = {}
        opts[:api_key] = kwargs.delete(:api_key) if kwargs.key?(:api_key)

        # Map object/record_id to parent_object/parent_record_id
        normalized_params = {
          parent_object: kwargs[:object] || kwargs[:parent_object],
          parent_record_id: kwargs[:record_id] || kwargs[:parent_record_id],
          title: kwargs[:title] || kwargs[:content] || "Note",
          content: kwargs[:content],
          format: kwargs[:format]
        }

        prepared_params = prepare_params_for_create(normalized_params)
        response = execute_request(:POST, resource_path, prepared_params, opts)
        new(response["data"] || response, opts)
      end

      # Override create to handle validation
      def prepare_params_for_create(params)
        validate_parent!(params[:parent_object], params[:parent_record_id])
        validate_content!(params[:content])
        validate_format!(params[:format]) if params[:format]

        {
          data: {
            title: params[:title],
            parent_object: params[:parent_object],
            parent_record_id: params[:parent_record_id],
            content: params[:content],
            format: params[:format] || "plaintext"
          }
        }
      end

      # Get notes for a record
      def for_record(params = {}, object:, record_id:, **)
        list(
          params.merge(
            parent_object: object,
            parent_record_id: record_id
          ),
          **
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
          raise ArgumentError, "Invalid format: #{format}. Valid formats: #{valid_formats.join(", ")}"
        end
      end
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
