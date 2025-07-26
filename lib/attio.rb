# frozen_string_literal: true

require_relative "attio/version"
require_relative "attio/util/configuration"
require_relative "attio/util/connection_manager"
require_relative "attio/util/request_builder"
require_relative "attio/util/response_parser"
require_relative "attio/errors"
require_relative "attio/api_operations/create"
require_relative "attio/api_operations/retrieve"
require_relative "attio/api_operations/update"
require_relative "attio/api_operations/delete"
require_relative "attio/api_operations/list"
require_relative "attio/resources/base"
require_relative "attio/resources/object"
require_relative "attio/resources/record"
require_relative "attio/resources/attribute"
require_relative "attio/resources/list"
require_relative "attio/resources/list_entry"
require_relative "attio/resources/webhook"
require_relative "attio/resources/workspace_member"
require_relative "attio/resources/note"
require_relative "attio/util/webhook_signature"
require_relative "attio/util/cache"
require_relative "attio/services/base_service"
require_relative "attio/services/person_service"
require_relative "attio/services/company_service"
require_relative "attio/services/batch_service"
require_relative "attio/oauth/client"
require_relative "attio/oauth/token"
require_relative "attio/oauth/scope_validator"

module Attio
  class Error < StandardError; end

  # Main entry point for the Attio Ruby client library
  class << self
    def configuration
      @configuration ||= Util::Configuration.new.tap(&:apply_env_vars!)
    end

    def configure(&block)
      configuration.configure(&block)
    end

    def reset!
      @configuration = nil
    end

    def api_key
      configuration.api_key
    end

    def api_key=(value)
      configuration.api_key = value
    end

    def api_base
      configuration.api_base
    end

    def api_version
      configuration.api_version
    end
  end
end
