# frozen_string_literal: true

require_relative "../api_resource"

module Attio
  class Note < APIResource
    api_operations :list, :retrieve, :create, :delete

    def self.resource_path
      "notes"
    end

    # Override id_key to use note_id
    def self.id_key
      :note_id
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
      @format = normalized_attrs[:format] || FormatTypes::PLAINTEXT
      @created_by_actor = normalized_attrs[:created_by_actor]
      @content_plaintext = normalized_attrs[:content_plaintext]
    end

    # Get the parent record
    def parent_record(**)
      return nil unless parent_object && parent_record_id

      Record.retrieve(
        object: parent_object,
        record_id: parent_record_id,
        **
      )
    end

    # Check if note is in HTML format
    def html?
      format == FormatTypes::HTML
    end

    # Check if note is in plaintext format
    def plaintext?
      format == FormatTypes::PLAINTEXT
    end

    # Get plaintext version of content
    def to_plaintext
      content_plaintext || strip_html(content)
    end

    # Override destroy to handle nested ID
    def destroy(**)
      raise InvalidRequestError, "Cannot destroy a note without an ID" unless persisted?

      note_id = id.is_a?(Hash) ? id["note_id"] : id
      self.class.delete(note_id: note_id, **)
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
      # Override retrieve to handle nested ID
      def retrieve(note_id:, **opts)
        # Handle both simple ID and nested hash for backwards compatibility
        actual_id = note_id.is_a?(Hash) ? note_id["note_id"] : note_id
        validate_id!(actual_id)
        path = Util::PathBuilder.build_resource_path(resource_path, actual_id)
        response = execute_request(HTTPMethods::GET, path, {}, opts)
        new(response["data"] || response, opts)
      end

      # Override create to handle validation and parameter mapping
      def create(parent_object:, parent_record_id:, content:, title: nil, format: FormatTypes::PLAINTEXT, **opts)
        # Support aliases for backwards compatibility
        parent_object ||= opts.delete(:object)
        parent_record_id ||= opts.delete(:record_id)

        normalized_params = {
          parent_object: parent_object,
          parent_record_id: parent_record_id,
          title: title || content || "Note",
          content: content,
          format: format
        }

        prepared_params = prepare_params_for_create(normalized_params)
        response = execute_request(HTTPMethods::POST, resource_path, prepared_params, opts)
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
            format: params[:format] || FormatTypes::PLAINTEXT
          }
        }
      end

      # Get notes for a record
      def for_record(object:, record_id:, **params)
        list(
          parent_object: object,
          parent_record_id: record_id,
          **params
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
