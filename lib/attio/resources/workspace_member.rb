# frozen_string_literal: true

require_relative "base"
require_relative "../api_operations/list"
require_relative "../api_operations/retrieve"

module Attio
  class WorkspaceMember < Resources::Base
    include APIOperations::List
    include APIOperations::Retrieve

    def self.resource_path
      "/workspace_members"
    end

    attr_reader :email_address, :first_name, :last_name, :avatar_url,
      :access_level, :status, :invited_at, :last_accessed_at

    def initialize(attributes = {}, opts = {})
      super
      # Now we can safely use symbol keys only since parent normalized them
      normalized_attrs = normalize_attributes(attributes)
      @email_address = normalized_attrs[:email_address]
      @first_name = normalized_attrs[:first_name]
      @last_name = normalized_attrs[:last_name]
      @avatar_url = normalized_attrs[:avatar_url]
      @access_level = normalized_attrs[:access_level]
      @status = normalized_attrs[:status]
      @invited_at = parse_timestamp(normalized_attrs[:invited_at])
      @last_accessed_at = parse_timestamp(normalized_attrs[:last_accessed_at])
    end

    # Get full name
    def full_name
      [first_name, last_name].compact.join(" ")
    end

    # Check if member is active
    def active?
      status == "active"
    end

    # Check if member is invited
    def invited?
      status == "invited"
    end

    # Check if member is deactivated
    def deactivated?
      status == "deactivated"
    end

    # Check if member is admin
    def admin?
      access_level == "admin"
    end

    # Check if member is standard user
    def standard?
      access_level == "standard"
    end

    def to_h
      super.merge(
        email_address: email_address,
        first_name: first_name,
        last_name: last_name,
        avatar_url: avatar_url,
        access_level: access_level,
        status: status,
        invited_at: invited_at&.iso8601,
        last_accessed_at: last_accessed_at&.iso8601
      ).compact
    end

    class << self
      # Get the current user (the API key owner)
      def me(opts = {})
        request = RequestBuilder.build(
          method: :GET,
          path: "#{resource_path}/me",
          headers: opts[:headers] || {},
          api_key: opts[:api_key]
        )

        response = connection_manager.execute(request)
        parsed = ResponseParser.parse(response, request)

        new(parsed, opts)
      end
      alias_method :current, :me

      # Find member by email
      def find_by_email(email, opts = {})
        list(opts).find { |member| member.email_address == email } ||
          raise(Errors::NotFoundError, "Workspace member with email '#{email}' not found")
      end

      # List active members only
      def active(opts = {})
        list(opts).select(&:active?)
      end

      # List admin members only
      def admins(opts = {})
        list(opts).select(&:admin?)
      end

      # This resource doesn't support creation or updates
      def create(*)
        raise NotImplementedError, "Workspace members cannot be created via API"
      end

      def update(*)
        raise NotImplementedError, "Workspace members cannot be updated via API"
      end

      def delete(*)
        raise NotImplementedError, "Workspace members cannot be deleted via API"
      end
    end

    # Instance methods that are not supported
    def save(*)
      raise NotImplementedError, "Workspace members cannot be updated via API"
    end

    def destroy(*)
      raise NotImplementedError, "Workspace members cannot be deleted via API"
    end
  end
end
