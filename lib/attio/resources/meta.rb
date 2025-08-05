# frozen_string_literal: true

require_relative "../api_resource"

module Attio
  # Provides metadata about the current API token and workspace
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

    # Build workspace object from flat attributes
    def workspace
      return nil unless self[:workspace_id]
      
      {
        id: self[:workspace_id],
        name: self[:workspace_name],
        slug: self[:workspace_slug],
        logo_url: self[:workspace_logo_url]
      }.compact
    end
    
    # Build token object from flat attributes
    def token
      return nil unless self[:client_id]
      
      {
        id: self[:client_id],
        type: self[:token_type] || "Bearer",
        scope: self[:scope]
      }.compact
    end
    
    # Build actor object from flat attributes
    def actor
      return nil unless self[:authorized_by_workspace_member_id]
      
      {
        type: "workspace-member",
        id: self[:authorized_by_workspace_member_id]
      }
    end

    # Convenience methods for workspace info
    def workspace_id
      self[:workspace_id]
    end

    # Get the workspace name
    # @return [String, nil] The workspace name
    def workspace_name
      self[:workspace_name]
    end

    # Get the workspace slug
    # @return [String, nil] The workspace slug
    def workspace_slug
      self[:workspace_slug]
    end

    # Convenience methods for token info
    def token_id
      self[:client_id]
    end

    # Get the token name
    # @return [String, nil] The token name (not available in flat format)
    def token_name
      nil
    end

    # Get the token type
    # @return [String, nil] The token type
    def token_type
      self[:token_type]
    end

    # Get the token's OAuth scopes
    # @return [Array<String>] Array of scope strings
    def scopes
      return [] unless self[:scope]
      self[:scope].split(" ")
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

    private
  end
end
