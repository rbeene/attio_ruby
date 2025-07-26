# frozen_string_literal: true

module Attio
  module OAuth
    class ScopeValidator
      # Define all valid scopes with their descriptions
      SCOPE_DEFINITIONS = {
        # Record scopes
        "record:read" => "Read access to records",
        "record:write" => "Write access to records (includes read)",
        
        # Object scopes
        "object:read" => "Read access to objects and their configuration",
        "object:write" => "Write access to objects (includes read)",
        
        # List scopes
        "list:read" => "Read access to lists and list entries",
        "list:write" => "Write access to lists (includes read)",
        
        # Webhook scopes
        "webhook:read" => "Read access to webhooks",
        "webhook:write" => "Write access to webhooks (includes read)",
        
        # User scopes
        "user:read" => "Read access to workspace members",
        
        # Note scopes
        "note:read" => "Read access to notes",
        "note:write" => "Write access to notes (includes read)",
        
        # Attribute scopes
        "attribute:read" => "Read access to attributes",
        "attribute:write" => "Write access to attributes (includes read)",
        
        # Comment scopes
        "comment:read" => "Read access to comments",
        "comment:write" => "Write access to comments (includes read)",
        
        # Task scopes
        "task:read" => "Read access to tasks",
        "task:write" => "Write access to tasks (includes read)"
      }.freeze

      VALID_SCOPES = SCOPE_DEFINITIONS.keys.freeze

      # Scope hierarchy - write scopes include read scopes
      SCOPE_HIERARCHY = {
        "record:write" => ["record:read"],
        "object:write" => ["object:read"],
        "list:write" => ["list:read"],
        "webhook:write" => ["webhook:read"],
        "note:write" => ["note:read"],
        "attribute:write" => ["attribute:read"],
        "comment:write" => ["comment:read"],
        "task:write" => ["task:read"]
      }.freeze

      class << self
        def validate(scopes)
          scopes = Array(scopes).map(&:to_s)
          invalid_scopes = scopes - VALID_SCOPES
          
          unless invalid_scopes.empty?
            raise InvalidScopeError, "Invalid scopes: #{invalid_scopes.join(', ')}"
          end
          
          scopes
        end

        def validate!(scopes)
          validate(scopes)
          true
        end

        def valid?(scope)
          VALID_SCOPES.include?(scope.to_s)
        end

        def description(scope)
          SCOPE_DEFINITIONS[scope.to_s]
        end

        # Check if a set of scopes includes a specific permission
        def includes?(scopes, required_scope)
          scopes = Array(scopes).map(&:to_s)
          required = required_scope.to_s
          
          return true if scopes.include?(required)
          
          # Check if any scope in the set provides the required scope
          scopes.any? do |scope|
            implied_scopes = SCOPE_HIERARCHY[scope] || []
            implied_scopes.include?(required)
          end
        end

        # Expand scopes to include all implied scopes
        def expand(scopes)
          scopes = Array(scopes).map(&:to_s)
          expanded = Set.new(scopes)
          
          scopes.each do |scope|
            implied = SCOPE_HIERARCHY[scope] || []
            expanded.merge(implied)
          end
          
          expanded.to_a.sort
        end

        # Get minimal set of scopes (remove redundant read scopes)
        def minimize(scopes)
          scopes = Array(scopes).map(&:to_s)
          minimized = scopes.dup
          
          SCOPE_HIERARCHY.each do |write_scope, read_scopes|
            if minimized.include?(write_scope)
              minimized -= read_scopes
            end
          end
          
          minimized.sort
        end

        # Group scopes by resource type
        def group_by_resource(scopes)
          scopes = Array(scopes).map(&:to_s)
          grouped = {}
          
          scopes.each do |scope|
            resource = scope.split(":").first
            grouped[resource] ||= []
            grouped[resource] << scope
          end
          
          grouped
        end

        # Check if scopes are sufficient for an operation
        def sufficient_for?(scopes, resource:, operation:)
          required_scope = "#{resource}:#{operation}"
          includes?(scopes, required_scope)
        end
      end

      class InvalidScopeError < StandardError; end
    end
  end
end