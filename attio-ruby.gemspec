# frozen_string_literal: true

require_relative "lib/attio/version"

Gem::Specification.new do |spec|
  spec.name = "attio-ruby"
  spec.version = Attio::VERSION
  spec.authors = ["Attio Team"]
  spec.email = ["support@attio.com"]

  spec.summary = "Ruby client library for the Attio API"
  spec.description = "A comprehensive Ruby client library for the Attio CRM API with OAuth support, type safety, and extensive test coverage"
  spec.homepage = "https://github.com/attio/attio-ruby"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/attio/attio-ruby"
  spec.metadata["changelog_uri"] = "https://github.com/attio/attio-ruby/blob/main/CHANGELOG.md"
  spec.metadata["documentation_uri"] = "https://rubydoc.info/gems/attio-ruby"
  spec.metadata["bug_tracker_uri"] = "https://github.com/attio/attio-ruby/issues"

  # Specify which files should be added to the gem when it is released.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Zero runtime dependencies as per the plan
  # All dependencies are development only

  # Development dependencies
  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.12"
  spec.add_development_dependency "webmock", "~> 3.18"
  spec.add_development_dependency "vcr", "~> 6.1"
  spec.add_development_dependency "simplecov", "~> 0.22"
  spec.add_development_dependency "yard", "~> 0.9"
  spec.add_development_dependency "rubocop", "~> 1.50"
  spec.add_development_dependency "rubocop-rspec", "~> 2.20"
  spec.add_development_dependency "rubocop-performance", "~> 1.17"
  spec.add_development_dependency "standard", "~> 1.28"
  spec.add_development_dependency "benchmark-ips", "~> 2.12"
  spec.add_development_dependency "pry", "~> 0.14"
  spec.add_development_dependency "pry-byebug", "~> 3.10"
  spec.add_development_dependency "dotenv", "~> 2.8"
  spec.add_development_dependency "timecop", "~> 0.9"
  spec.add_development_dependency "bundle-audit", "~> 0.1"
  spec.add_development_dependency "brakeman", "~> 6.0"
  spec.metadata["rubygems_mfa_required"] = "true"
end
