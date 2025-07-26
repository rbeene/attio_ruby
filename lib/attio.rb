# frozen_string_literal: true

require_relative "attio/version"
require_relative "attio/util/configuration"
require_relative "attio/errors"

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
