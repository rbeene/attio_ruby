# frozen_string_literal: true

require "simplecov-cobertura"

SimpleCov.start do
  add_filter "/spec/"
  add_filter "/vendor/"
  
  # Generate both HTML and XML coverage reports
  formatter SimpleCov::Formatter::MultiFormatter.new([
    SimpleCov::Formatter::HTMLFormatter,
    SimpleCov::Formatter::CoberturaFormatter
  ])
  
  # Set coverage directory
  coverage_dir "coverage"
end