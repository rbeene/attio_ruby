# frozen_string_literal: true

require_relative "../api_resource"

module Attio
  class Meta < APIResource
    # Meta only supports the identify endpoint (no CRUD operations)

    def self.resource_path
      "self"
    end

    # Get information about the current token and workspace
    def self.identify(**opts)
      response = execute_request(:GET, resource_path, {}, opts)
      new(response["data"] || response, opts)
    end

    class << self
      # Convenient aliases
      alias_method :self, :identify
      alias_method :current, :identify
    end

    # Define attribute accessors
    attr_attio :workspace, :token, :actor

    # Convenience methods for workspace info
    def workspace_id
      workspace&.dig(:id)
    end

    def workspace_name
      workspace&.dig(:name)
    end

    def workspace_slug
      workspace&.dig(:slug)
    end

    # Convenience methods for token info
    def token_id
      token&.dig(:id)
    end

    def token_name
      token&.dig(:name)
    end

    def token_type
      token&.dig(:type)
    end

    def scopes
      token&.dig(:scopes) || []
    end

    # Check if token has a specific scope
    def has_scope?(scope)
      scope_str = scope.to_s.tr("_", ":")
      scopes.include?(scope_str)
    end

    # Check read/write permissions
    def can_read?(resource)
      has_scope?("#{resource}:read") || has_scope?("#{resource}:read-write")
    end

    def can_write?(resource)
      has_scope?("#{resource}:write") || has_scope?("#{resource}:read-write")
    end

    # Meta is read-only
    def immutable?
      true
    end

    # Override save to raise error since meta is read-only
    def save(**opts)
      raise InvalidRequestError, "Meta information is read-only"
    end

    # Override destroy to raise error since meta is read-only
    def destroy(**opts)
      raise InvalidRequestError, "Meta information is read-only"
    end

    private

    def to_h
      {
        workspace: workspace,
        token: token,
        actor: actor
      }.compact
    end

    def inspect
      "#<#{self.class.name}:#{object_id} workspace=#{workspace_slug.inspect} token=#{token_name.inspect}>"
    end
  end
end
