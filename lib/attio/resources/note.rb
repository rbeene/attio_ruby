# frozen_string_literal: true

require_relative "../api_resource"

module Attio
  class Note < APIResource
    api_operations :list, :retrieve, :create, :delete

    def self.resource_path
      "/notes"
    end

    # Read-only attributes - notes are immutable
    attr_reader :parent_object, :parent_record_id, :content, :format,
                :created_by_actor, :content_plaintext

    def initialize(attributes = {}, opts = {})
      super
      normalized_attrs = normalize_attributes(attributes)
      @parent_object = normalized_attrs[:parent_object]
      @parent_record_id = normalized_attrs[:parent_record_id]
      @content = normalized_attrs[:content]
      @format = normalized_attrs[:format] || "plaintext"
      @created_by_actor = normalized_attrs[:created_by_actor]
      @content_plaintext = normalized_attrs[:content_plaintext]
    end

    # Get the parent record
    def parent_record(**opts)
      return nil unless parent_object && parent_record_id

      Record.retrieve(
        object: parent_object,
        record_id: parent_record_id,
        **opts
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

    # Notes cannot be updated
    def save(*)
      raise NotImplementedError, "Notes cannot be updated. Create a new note instead."
    end

    def update(*)
      raise NotImplementedError, "Notes cannot be updated. Create a new note instead."
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
      # Override create to handle validation
      def prepare_params_for_create(params)
        validate_parent!(params[:parent_object], params[:parent_record_id])
        validate_content!(params[:content])
        validate_format!(params[:format]) if params[:format]

        {
          parent_object: params[:parent_object],
          parent_record_id: params[:parent_record_id],
          content: params[:content],
          format: params[:format] || "plaintext"
        }
      end

      # Get notes for a record
      def for_record(params = {}, object:, record_id:, **opts)
        list(
          params.merge(
            parent_object: object,
            parent_record_id: record_id
          ),
          **opts
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