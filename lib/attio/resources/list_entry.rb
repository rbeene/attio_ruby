# frozen_string_literal: true

require_relative "base"
require_relative "../api_operations/list"
require_relative "../api_operations/retrieve"
require_relative "../api_operations/create"
require_relative "../api_operations/delete"

module Attio
  class ListEntry < Resources::Base
    include APIOperations::Delete

    def self.resource_path
      "/lists"
    end

    attr_reader :list_id, :record_id, :added_by_actor

    def initialize(attributes = {}, opts = {})
      super
      @list_id = attributes[:list_id] || attributes["list_id"]
      @record_id = attributes[:record_id] || attributes["record_id"]
      @added_by_actor = attributes[:added_by_actor] || attributes["added_by_actor"]
      @record = attributes[:record] || attributes["record"]
    end

    # Get the list this entry belongs to
    def list(opts = {})
      return nil unless list_id
      List.retrieve(list_id, opts)
    end

    # Get the full record data
    def record(opts = {})
      return @record if @record&.is_a?(Record)
      return nil unless record_id

      # Need to get the object information from the list
      list_obj = list(opts)
      Record.retrieve(object: list_obj.object_api_slug, record_id: record_id, opts: opts)
    end

    # Remove this entry from the list
    def destroy(opts = {})
      self.class.delete(list_id: list_id, entry_id: id, opts: opts)
    end
    alias_method :delete, :destroy
    alias_method :remove, :destroy

    def to_h
      super.merge(
        list_id: list_id,
        record_id: record_id,
        added_by_actor: added_by_actor,
        record: @record.is_a?(Record) ? @record.to_h : @record
      ).compact
    end

    def resource_path
      "#{self.class.resource_path}/#{list_id}/entries/#{id}"
    end

    class << self
      # List entries in a list
      def list(params = {}, list_id:, **opts)
        validate_list_id!(list_id)

        request = RequestBuilder.build(
          method: :GET,
          path: "#{resource_path}/#{list_id}/entries",
          params: params,
          headers: opts[:headers] || {},
          api_key: opts[:api_key]
        )

        response = connection_manager.execute(request)
        parsed = ResponseParser.parse(response, request)

        # Add list_id to each entry for context
        if parsed.is_a?(Hash) && parsed[:data]
          parsed[:data].each { |entry| entry[:list_id] = list_id }
        end

        APIOperations::List::ListObject.new(parsed, self, params.merge(list_id: list_id), opts)
      end
      alias_method :all, :list

      # Add a record to a list
      def create(list_id:, record_id:, opts: {})
        validate_list_id!(list_id)
        validate_record_id!(record_id)

        request = RequestBuilder.build(
          method: :POST,
          path: "#{resource_path}/#{list_id}/entries",
          params: {record_id: record_id},
          headers: opts[:headers] || {},
          api_key: opts[:api_key]
        )

        response = connection_manager.execute(request)
        parsed = ResponseParser.parse(response, request)

        # Add list_id for context
        parsed[:list_id] = list_id if parsed.is_a?(Hash)

        new(parsed, opts)
      end
      alias_method :add, :create

      # Remove an entry from a list
      def delete(list_id:, entry_id:, opts: {})
        validate_list_id!(list_id)
        validate_entry_id!(entry_id)

        request = RequestBuilder.build(
          method: :DELETE,
          path: "#{resource_path}/#{list_id}/entries/#{entry_id}",
          headers: opts[:headers] || {},
          api_key: opts[:api_key]
        )

        response = connection_manager.execute(request)
        ResponseParser.parse(response, request)

        true
      end
      alias_method :destroy, :delete
      alias_method :remove, :delete

      # Get a specific entry
      def retrieve(list_id:, entry_id:, opts: {})
        validate_list_id!(list_id)
        validate_entry_id!(entry_id)

        request = RequestBuilder.build(
          method: :GET,
          path: "#{resource_path}/#{list_id}/entries/#{entry_id}",
          headers: opts[:headers] || {},
          api_key: opts[:api_key]
        )

        response = connection_manager.execute(request)
        parsed = ResponseParser.parse(response, request)

        # Add list_id for context
        parsed[:list_id] = list_id if parsed.is_a?(Hash)

        new(parsed, opts)
      end
      alias_method :get, :retrieve
      alias_method :find, :retrieve

      # Bulk add records to a list
      def create_batch(list_id:, record_ids:, opts: {})
        validate_list_id!(list_id)
        raise ArgumentError, "record_ids must be an array" unless record_ids.is_a?(Array)
        raise ArgumentError, "record_ids cannot be empty" if record_ids.empty?

        request = RequestBuilder.build(
          method: :POST,
          path: "#{resource_path}/#{list_id}/entries/batch",
          params: {record_ids: record_ids},
          headers: opts[:headers] || {},
          api_key: opts[:api_key]
        )

        response = connection_manager.execute(request)
        parsed = ResponseParser.parse(response, request)

        # Return array of created entries
        entries = parsed[:data] || []
        entries.map do |entry_data|
          entry_data[:list_id] = list_id
          new(entry_data, opts)
        end
      end
      alias_method :add_batch, :create_batch

      # Bulk remove records from a list
      def delete_batch(list_id:, entry_ids:, opts: {})
        validate_list_id!(list_id)
        raise ArgumentError, "entry_ids must be an array" unless entry_ids.is_a?(Array)
        raise ArgumentError, "entry_ids cannot be empty" if entry_ids.empty?

        request = RequestBuilder.build(
          method: :DELETE,
          path: "#{resource_path}/#{list_id}/entries/batch",
          params: {entry_ids: entry_ids},
          headers: opts[:headers] || {},
          api_key: opts[:api_key]
        )

        response = connection_manager.execute(request)
        ResponseParser.parse(response, request)

        true
      end
      alias_method :remove_batch, :delete_batch

      private

      def validate_list_id!(list_id)
        raise ArgumentError, "list_id is required" if list_id.nil? || list_id.to_s.empty?
      end

      def validate_record_id!(record_id)
        raise ArgumentError, "record_id is required" if record_id.nil? || record_id.to_s.empty?
      end

      def validate_entry_id!(entry_id)
        raise ArgumentError, "entry_id is required" if entry_id.nil? || entry_id.to_s.empty?
      end
    end
  end
end
