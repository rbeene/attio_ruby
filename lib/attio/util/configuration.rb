# frozen_string_literal: true

module Attio
  module Util
    class Configuration
      class ConfigurationError < ::Attio::InvalidRequestError; end

      REQUIRED_SETTINGS = %i[api_key].freeze
      OPTIONAL_SETTINGS = %i[
        api_base
        api_version
        timeout
        open_timeout
        max_retries
        logger
        debug
        ca_bundle_path
        verify_ssl_certs
        use_faraday
      ].freeze

      ALL_SETTINGS = (REQUIRED_SETTINGS + OPTIONAL_SETTINGS).freeze

      # Default configuration values
      DEFAULT_SETTINGS = {
        api_base: APIDefaults::BASE_URL,
        api_version: APIDefaults::API_VERSION,
        timeout: APIDefaults::DEFAULT_TIMEOUT,
        open_timeout: 10,      # Connection timeout in seconds
        max_retries: APIDefaults::MAX_RETRIES,
        logger: nil,           # Logger instance for debug output
        debug: false,          # Enable debug logging
        ca_bundle_path: nil,   # Custom CA bundle path
        verify_ssl_certs: true, # Verify SSL certificates
        use_faraday: true     # Use Faraday (always true now)
      }.freeze

      attr_reader(*ALL_SETTINGS)

      def initialize
        @configured = false
        reset_without_lock!
      end

      def reset!
        reset_without_lock!
        @configured = false
      end

      def configure
        raise ConfigurationError, "Configuration has already been finalized" if frozen?

        yield(self) if block_given?
        validate!
        @configured = true
      end

      # Call this to make configuration immutable
      def finalize!
        validate!
        freeze unless frozen?
      end

      def validate!
        REQUIRED_SETTINGS.each do |setting|
          value = instance_variable_get("@#{setting}")
          if value.nil? || (value.respond_to?(:empty?) && value.empty?)
            raise ConfigurationError, "#{setting} must be configured"
          end
        end

        raise ConfigurationError, "timeout must be positive" if @timeout && @timeout <= 0
        raise ConfigurationError, "open_timeout must be positive" if @open_timeout && @open_timeout <= 0
        raise ConfigurationError, "max_retries must be non-negative" if @max_retries&.negative?

        true
      end

      def to_h
        ALL_SETTINGS.each_with_object({}) do |setting, hash|
          hash[setting] = instance_variable_get("@#{setting}")
        end
      end

      def apply_env_vars!
        raise ConfigurationError, "Cannot modify frozen configuration" if frozen?

        @api_key = ENV.fetch("ATTIO_API_KEY", @api_key)
        @api_base = ENV.fetch("ATTIO_API_BASE", @api_base)
        @api_version = ENV.fetch("ATTIO_API_VERSION", @api_version)
        @timeout = ENV.fetch("ATTIO_TIMEOUT", @timeout).to_i if ENV.key?("ATTIO_TIMEOUT")
        @open_timeout = ENV.fetch("ATTIO_OPEN_TIMEOUT", @open_timeout).to_i if ENV.key?("ATTIO_OPEN_TIMEOUT")
        @max_retries = ENV.fetch("ATTIO_MAX_RETRIES", @max_retries).to_i if ENV.key?("ATTIO_MAX_RETRIES")
        @debug = ENV.fetch("ATTIO_DEBUG", @debug).to_s.downcase == "true" if ENV.key?("ATTIO_DEBUG")
        @ca_bundle_path = ENV.fetch("ATTIO_CA_BUNDLE_PATH", @ca_bundle_path) if ENV.key?("ATTIO_CA_BUNDLE_PATH")
        @verify_ssl_certs = ENV.fetch("ATTIO_VERIFY_SSL_CERTS", @verify_ssl_certs).to_s.downcase != "false" if ENV.key?("ATTIO_VERIFY_SSL_CERTS")
        @use_faraday = ENV.fetch("ATTIO_USE_FARADAY", @use_faraday).to_s.downcase != "false" if ENV.key?("ATTIO_USE_FARADAY")

        if ENV.key?("ATTIO_LOGGER")
          logger_class = ENV["ATTIO_LOGGER"]
          @logger = (logger_class == "STDOUT") ? Logger.new($stdout) : nil
        end
      end

      def merge(options)
        dup.tap do |config|
          options.each do |key, value|
            if ALL_SETTINGS.include?(key.to_sym)
              config.instance_variable_set("@#{key}", value)
            end
          end
        end
      end

      def dup
        self.class.new.tap do |config|
          ALL_SETTINGS.each do |setting|
            config.instance_variable_set("@#{setting}", instance_variable_get("@#{setting}"))
          end
        end
      end

      # Setters - only work before configuration is frozen
      ALL_SETTINGS.each do |setting|
        define_method("#{setting}=") do |value|
          raise ConfigurationError, "Cannot modify frozen configuration" if frozen?
          instance_variable_set("@#{setting}", value)
        end
      end

      private

      def reset_without_lock!
        DEFAULT_SETTINGS.each do |key, value|
          instance_variable_set("@#{key}", value)
        end
        @api_key = nil
      end
    end
  end
end
