# frozen_string_literal: true

require_relative "attio/version"
require_relative "attio/errors"
require_relative "attio/util/configuration"
require_relative "attio/util/connection_manager"
require_relative "attio/util/faraday_connection_manager"
require_relative "attio/util/request_builder"
require_relative "attio/util/response_parser"
require_relative "attio/resources/base"
require_relative "attio/api_resource"
require_relative "attio/resources/object"
require_relative "attio/resources/record_v2"
require_relative "attio/resources/attribute"
require_relative "attio/resources/list_v2"
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

# Attio Ruby SDK
#
# The official Ruby client library for the Attio API. This library provides
# a simple and intuitive interface for interacting with Attio's CRM platform.
#
# @example Basic configuration
#   Attio.configure do |config|
#     config.api_key = "your_api_key"
#   end
#
# @example Creating a record
#   person = Attio::Record.create(
#     object: "people",
#     values: {
#       name: "John Doe",
#       email_addresses: "john@example.com"
#     }
#   )
#
# @see https://attio.com/docs API Documentation
# @see https://github.com/attio/attio-ruby GitHub Repository
module Attio
  # Base error class for all Attio-specific errors
  class Error < StandardError; end

  # Main entry point for the Attio Ruby client library
  class << self
    # Returns the current configuration object
    #
    # @return [Attio::Util::Configuration] The configuration instance
    def configuration
      @configuration ||= Util::Configuration.new.tap(&:apply_env_vars!)
    end

    # Configures the Attio client
    #
    # @yield [config] Configuration block
    # @yieldparam config [Attio::Util::Configuration] The configuration object
    #
    # @example
    #   Attio.configure do |config|
    #     config.api_key = "your_api_key"
    #     config.timeout = 30
    #     config.debug = true
    #   end
    def configure(&block)
      configuration.configure(&block)
    end

    # Resets the configuration to defaults
    #
    # @return [nil]
    def reset!
      @configuration = nil
    end

    # Gets the current API key
    #
    # @return [String, nil] The API key
    def api_key
      configuration.api_key
    end

    # Sets the API key
    #
    # @param value [String] The API key
    # @return [String] The API key
    def api_key=(value)
      configuration.api_key = value
    end

    # Gets the API base URL
    #
    # @return [String] The API base URL
    def api_base
      configuration.api_base
    end

    # Gets the API version
    #
    # @return [String] The API version
    def api_version
      configuration.api_version
    end

    # Creates a new connection manager instance
    #
    # @return [Util::ConnectionManager, Util::FaradayConnectionManager] The connection manager
    def connection_manager
      if configuration.use_faraday
        Util::FaradayConnectionManager.new
      else
        Util::ConnectionManager.new
      end
    end
  end
end
