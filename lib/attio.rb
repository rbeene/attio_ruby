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
