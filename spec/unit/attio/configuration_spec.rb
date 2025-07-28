# frozen_string_literal: true

RSpec.describe Attio::Util::Configuration do
  let(:config) { described_class.new }

  describe "#initialize" do
    it "sets default API base URL" do
      expect(config.api_base).to eq("https://api.attio.com")
    end

    it "sets default API version" do
      expect(config.api_version).to eq("v2")
    end

    it "sets default timeout" do
      expect(config.timeout).to eq(120)
    end

    it "sets default open timeout" do
      expect(config.open_timeout).to eq(10)
    end

    it "sets default max retries" do
      expect(config.max_retries).to eq(3)
    end

    it "disables debug mode by default" do
      expect(config.debug).to be false
    end

    it "enables SSL verification by default" do
      expect(config.verify_ssl_certs).to be true
    end
  end

  describe "#configure" do
    it "yields the configuration object" do
      config.configure do |c|
        c.api_key = "test_key"
        c.timeout = 60
      end

      expect(config.api_key).to eq("test_key")
      expect(config.timeout).to eq(60)
    end

    it "validates configuration after yield" do
      # First set a valid api_key so validation doesn't fail on that
      config.api_key = "test_key"

      expect do
        config.configure do |c|
          c.timeout = -1
        end
      end.to raise_error(Attio::Util::Configuration::ConfigurationError, "timeout must be positive")
    end

    it "is thread-safe" do
      # Test that concurrent configure blocks don't interfere with each other
      # Each thread should see its changes applied atomically
      errors = []
      threads = []

      10.times do |i|
        threads << Thread.new do
          config.configure do |c|
            c.api_key = "key_#{i}"
            c.timeout = 30 + i
            # Verify within the configure block that our changes are consistent
            if c.api_key != "key_#{i}" || c.timeout != 30 + i
              errors << "Thread #{i} saw inconsistent state"
            end
          end
        rescue => e
          errors << "Thread #{i} error: #{e.message}"
        end
      end

      threads.each(&:join)
      expect(errors).to be_empty

      # The final state should have one of the thread's values (whichever ran last)
      expect(config.api_key).to match(/^key_\d+$/)
      expect(config.timeout).to be_between(30, 39)
    end
  end

  describe "#validate!" do
    it "requires api_key" do
      expect do
        config.validate!
      end.to raise_error(Attio::Util::Configuration::ConfigurationError, "api_key must be configured")
    end

    it "validates timeout is positive" do
      config.api_key = "test"
      config.timeout = -1

      expect do
        config.validate!
      end.to raise_error(Attio::Util::Configuration::ConfigurationError, "timeout must be positive")
    end

    it "validates open_timeout is positive" do
      config.api_key = "test"
      config.open_timeout = 0

      expect do
        config.validate!
      end.to raise_error(Attio::Util::Configuration::ConfigurationError, "open_timeout must be positive")
    end

    it "validates max_retries is non-negative" do
      config.api_key = "test"
      config.max_retries = -1

      expect do
        config.validate!
      end.to raise_error(Attio::Util::Configuration::ConfigurationError, "max_retries must be non-negative")
    end

    it "passes with valid configuration" do
      config.api_key = "test"
      expect(config.validate!).to be true
    end
  end

  describe "#apply_env_vars!" do
    around do |example|
      # Save original env vars
      original_env = ENV.to_h

      # Run test
      example.run

      # Restore env vars
      ENV.clear
      original_env.each { |k, v| ENV[k] = v }
    end

    it "reads configuration from environment variables" do
      ENV["ATTIO_API_KEY"] = "env_key"
      ENV["ATTIO_API_BASE"] = "https://custom.api.com"
      ENV["ATTIO_TIMEOUT"] = "60"
      ENV["ATTIO_DEBUG"] = "true"

      config.apply_env_vars!

      expect(config.api_key).to eq("env_key")
      expect(config.api_base).to eq("https://custom.api.com")
      expect(config.timeout).to eq(60)
      expect(config.debug).to be true
    end

    it "handles verify_ssl_certs correctly" do
      ENV["ATTIO_VERIFY_SSL_CERTS"] = "false"
      config.apply_env_vars!
      expect(config.verify_ssl_certs).to be false

      ENV["ATTIO_VERIFY_SSL_CERTS"] = "true"
      config.apply_env_vars!
      expect(config.verify_ssl_certs).to be true
    end
  end

  describe "#to_h" do
    it "returns all settings as a hash" do
      config.api_key = "test"
      hash = config.to_h

      expect(hash).to include(
        api_key: "test",
        api_base: "https://api.attio.com",
        api_version: "v2",
        timeout: 120,
        open_timeout: 10,
        max_retries: 3,
        debug: false,
        verify_ssl_certs: true
      )
    end
  end

  describe "#dup" do
    it "creates a deep copy" do
      config.api_key = "original"
      copy = config.dup

      copy.api_key = "modified"

      expect(config.api_key).to eq("original")
      expect(copy.api_key).to eq("modified")
    end
  end

  describe "#merge" do
    it "creates a new config with merged options" do
      config.api_key = "original"
      config.timeout = 30

      merged = config.merge(api_key: "new", timeout: 60)

      expect(config.api_key).to eq("original")
      expect(config.timeout).to eq(30)
      expect(merged.api_key).to eq("new")
      expect(merged.timeout).to eq(60)
    end

    it "ignores unknown options" do
      merged = config.merge(unknown_option: "value")
      expect(merged.to_h.keys).not_to include(:unknown_option)
    end
  end

  describe "#reset!" do
    it "resets to default values" do
      config.api_key = "test"
      config.timeout = 60

      config.reset!

      expect(config.api_key).to be_nil
      expect(config.timeout).to eq(120)
    end
  end
end
