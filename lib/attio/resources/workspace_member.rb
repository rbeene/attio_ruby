# frozen_string_literal: true

require_relative "../api_resource"

module Attio
  class WorkspaceMember < APIResource
    api_operations :list, :retrieve

    def self.resource_path
      "/workspace_members"
    end

    # Read-only attributes - workspace members are immutable via API
    attr_reader :email_address, :first_name, :last_name, :avatar_url,
                :access_level, :status, :invited_at, :last_accessed_at

    def initialize(attributes = {}, opts = {})
      super
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

    # Workspace members cannot be modified via API
    def save(*)
      raise NotImplementedError, "Workspace members cannot be updated via API"
    end

    def update(*)
      raise NotImplementedError, "Workspace members cannot be updated via API"
    end

    def destroy(*)
      raise NotImplementedError, "Workspace members cannot be deleted via API"
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
      def me(**opts)
        response = execute_request(:GET, "#{resource_path}/me", {}, opts)
        new(response[:data] || response, opts)
      end
      alias_method :current, :me

      # Find member by email
      def find_by_email(email, **opts)
        list(**opts).find { |member| member.email_address == email } ||
          raise(NotFoundError, "Workspace member with email '#{email}' not found")
      end

      # List active members only
      def active(**opts)
        list(**opts).select(&:active?)
      end

      # List admin members only
      def admins(**opts)
        list(**opts).select(&:admin?)
      end

      # This resource doesn't support creation, updates, or deletion
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
  end
end