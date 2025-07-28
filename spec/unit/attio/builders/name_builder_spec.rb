# frozen_string_literal: true

require "spec_helper"
require "attio/builders/name_builder"

RSpec.describe Attio::Builders::NameBuilder do
  describe "#first" do
    it "sets the first name" do
      builder = described_class.new.first("John")
      expect(builder.build).to eq([{first_name: "John", full_name: "John"}])
    end
  end

  describe "#last" do
    it "sets the last name" do
      builder = described_class.new.last("Doe")
      expect(builder.build).to eq([{last_name: "Doe", full_name: "Doe"}])
    end
  end

  describe "#middle" do
    it "sets the middle name" do
      builder = described_class.new.first("John").middle("Michael").last("Doe")
      expect(builder.build).to eq([{
        first_name: "John",
        middle_name: "Michael",
        last_name: "Doe",
        full_name: "John Michael Doe"
      }])
    end
  end

  describe "#prefix" do
    it "sets the name prefix" do
      builder = described_class.new.prefix("Dr.").first("John").last("Doe")
      expect(builder.build).to eq([{
        prefix: "Dr.",
        first_name: "John",
        last_name: "Doe",
        full_name: "Dr. John Doe"
      }])
    end
  end

  describe "#suffix" do
    it "sets the name suffix" do
      builder = described_class.new.first("John").last("Doe").suffix("Jr.")
      expect(builder.build).to eq([{
        first_name: "John",
        last_name: "Doe",
        suffix: "Jr.",
        full_name: "John Doe Jr."
      }])
    end
  end

  describe "#full" do
    it "sets a custom full name" do
      builder = described_class.new.first("John").last("Doe").full("Johnny Doe")
      expect(builder.build).to eq([{
        first_name: "John",
        last_name: "Doe",
        full_name: "Johnny Doe"
      }])
    end
  end

  describe "#build" do
    it "returns an array with a single hash" do
      result = described_class.new.first("Jane").build
      expect(result).to be_an(Array)
      expect(result.length).to eq(1)
      expect(result.first).to be_a(Hash)
    end

    it "generates full name from components" do
      builder = described_class.new
        .prefix("Prof.")
        .first("Jane")
        .middle("Marie")
        .last("Smith")
        .suffix("PhD")

      result = builder.build
      expect(result.first[:full_name]).to eq("Prof. Jane Marie Smith PhD")
    end

    it "returns empty array data when no components set" do
      result = described_class.new.build
      expect(result).to eq([{}])
    end
  end

  describe "#parse" do
    it "parses a simple first last name" do
      builder = described_class.new.parse("John Doe")
      result = builder.build

      expect(result.first[:first_name]).to eq("John")
      expect(result.first[:last_name]).to eq("Doe")
      expect(result.first[:full_name]).to eq("John Doe")
    end

    it "parses a single name as first name" do
      builder = described_class.new.parse("Madonna")
      result = builder.build

      expect(result.first[:first_name]).to eq("Madonna")
      expect(result.first[:last_name]).to be_nil
    end

    it "parses three-part names as first middle last" do
      builder = described_class.new.parse("John Michael Doe")
      result = builder.build

      expect(result.first[:first_name]).to eq("John")
      expect(result.first[:middle_name]).to eq("Michael")
      expect(result.first[:last_name]).to eq("Doe")
    end

    it "recognizes common prefixes" do
      builder = described_class.new.parse("Dr John Doe")
      result = builder.build

      expect(result.first[:prefix]).to eq("Dr")
      expect(result.first[:first_name]).to eq("John")
      expect(result.first[:last_name]).to eq("Doe")
    end

    it "recognizes common suffixes" do
      builder = described_class.new.parse("John Doe Jr")
      result = builder.build

      expect(result.first[:first_name]).to eq("John")
      expect(result.first[:last_name]).to eq("Doe")
      expect(result.first[:suffix]).to eq("Jr")
    end

    it "handles complex names with prefix and suffix" do
      builder = described_class.new.parse("Dr John Michael Doe PhD")
      result = builder.build

      expect(result.first[:prefix]).to eq("Dr")
      expect(result.first[:first_name]).to eq("John")
      expect(result.first[:middle_name]).to eq("Michael")
      expect(result.first[:last_name]).to eq("Doe")
      expect(result.first[:suffix]).to eq("PhD")
    end

    it "preserves the original full name" do
      builder = described_class.new.parse("John Q. Public")
      result = builder.build

      expect(result.first[:full_name]).to eq("John Q. Public")
    end
  end

  describe ".build" do
    it "builds from a string" do
      result = described_class.build("John Doe")
      expect(result.first[:first_name]).to eq("John")
      expect(result.first[:last_name]).to eq("Doe")
    end

    it "builds from a hash with full keys" do
      result = described_class.build({
        first_name: "John",
        last_name: "Doe",
        middle_name: "Michael"
      })

      expect(result.first[:first_name]).to eq("John")
      expect(result.first[:middle_name]).to eq("Michael")
      expect(result.first[:last_name]).to eq("Doe")
    end

    it "builds from a hash with short keys" do
      result = described_class.build({
        first: "Jane",
        last: "Smith",
        prefix: "Ms."
      })

      expect(result.first[:first_name]).to eq("Jane")
      expect(result.first[:last_name]).to eq("Smith")
      expect(result.first[:prefix]).to eq("Ms.")
    end

    it "builds from an existing NameBuilder" do
      builder = described_class.new.first("John").last("Doe")
      result = described_class.build(builder)

      expect(result.first[:first_name]).to eq("John")
      expect(result.first[:last_name]).to eq("Doe")
    end

    it "returns array input unchanged if already in correct format" do
      input = [{first_name: "John", last_name: "Doe"}]
      result = described_class.build(input)

      expect(result).to eq(input)
    end

    it "raises error for invalid input types" do
      expect {
        described_class.build(123)
      }.to raise_error(ArgumentError, /Invalid input type/)
    end
  end

  describe "method chaining" do
    it "supports fluent interface" do
      result = described_class.new
        .first("John")
        .middle("Q")
        .last("Public")
        .prefix("Mr.")
        .suffix("Esq.")
        .build

      expect(result.first).to include(
        first_name: "John",
        middle_name: "Q",
        last_name: "Public",
        prefix: "Mr.",
        suffix: "Esq.",
        full_name: "Mr. John Q Public Esq."
      )
    end
  end
end
