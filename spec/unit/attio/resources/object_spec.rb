# frozen_string_literal: true

require "spec_helper"

RSpec.describe Attio::Object do
  let(:object_attributes) do
    {
      id: {object_id: "obj_123"},
      api_slug: "people",
      singular_noun: "Person",
      plural_noun: "People",
      created_by_actor: {
        type: "user",
        id: "usr_123"
      }
    }
  end

  describe "#initialize" do
    it "sets attributes correctly" do
      object = described_class.new(object_attributes)

      expect(object.api_slug).to eq("people")
      expect(object.singular_noun).to eq("Person")
      expect(object.plural_noun).to eq("People")
      expect(object.created_by_actor).to eq({type: "user", id: "usr_123"})
    end

    it "handles string keys" do
      string_attrs = {
        "id" => {"object_id" => "obj_456"},
        "api_slug" => "companies",
        "singular_noun" => "Company",
        "plural_noun" => "Companies"
      }

      object = described_class.new(string_attrs)
      expect(object.api_slug).to eq("companies")
      expect(object.singular_noun).to eq("Company")
      expect(object.plural_noun).to eq("Companies")
    end
  end

  describe ".resource_path" do
    it "returns the correct path" do
      expect(described_class.resource_path).to eq("objects")
    end
  end

  describe "#attributes" do
    let(:object) { described_class.new(object_attributes) }

    it "fetches attributes for the object using api_slug" do
      allow(Attio::Attribute).to receive(:list).with(parent_object: "people")
      object.attributes
    end

    it "uses id when api_slug is nil" do
      object_without_slug = described_class.new(id: "obj_789")
      allow(Attio::Attribute).to receive(:list).with(parent_object: "obj_789")
      object_without_slug.attributes
    end

    it "passes additional options" do
      allow(Attio::Attribute).to receive(:list).with(parent_object: "people", api_key: "custom_key")
      object.attributes(api_key: "custom_key")
    end
  end

  describe "#create_attribute" do
    let(:object) { described_class.new(object_attributes) }

    it "creates an attribute for the object" do
      params = {name: "Custom Field", type: "text"}
      allow(Attio::Attribute).to receive(:create).with(
        {name: "Custom Field", type: "text", parent_object: "people"}
      )
      object.create_attribute(params)
    end

    it "uses id when api_slug is nil" do
      object_without_slug = described_class.new(id: "obj_789")
      allow(Attio::Attribute).to receive(:create).with(
        {name: "Field", parent_object: "obj_789"}
      )
      object_without_slug.create_attribute({name: "Field"})
    end

    it "passes additional options" do
      allow(Attio::Attribute).to receive(:create).with(
        {name: "Field", parent_object: "people"},
        {api_key: "custom_key"}
      )
      object.create_attribute({name: "Field"}, api_key: "custom_key")
    end
  end

  describe "#records" do
    let(:object) { described_class.new(object_attributes) }

    it "fetches records for the object" do
      allow(Attio::Record).to receive(:list).with(object: "people")
      object.records
    end

    it "passes query parameters" do
      params = {limit: 10, offset: 5}
      allow(Attio::Record).to receive(:list).with(object: "people", limit: 10, offset: 5)
      object.records(params)
    end

    it "uses id when api_slug is nil" do
      object_without_slug = described_class.new(id: "obj_789")
      allow(Attio::Record).to receive(:list).with(object: "obj_789")
      object_without_slug.records
    end

    it "passes additional options" do
      allow(Attio::Record).to receive(:list).with(object: "people", api_key: "custom_key")
      object.records({}, api_key: "custom_key")
    end
  end

  describe "#create_record" do
    let(:object) { described_class.new(object_attributes) }

    it "creates a record for the object" do
      values = {name: "John Doe", email: "john@example.com"}
      allow(Attio::Record).to receive(:create).with(
        object: "people",
        values: values
      )
      object.create_record(values)
    end

    it "uses id when api_slug is nil" do
      object_without_slug = described_class.new(id: "obj_789")
      values = {name: "Test"}
      allow(Attio::Record).to receive(:create).with(
        object: "obj_789",
        values: values
      )
      object_without_slug.create_record(values)
    end

    it "passes additional options" do
      values = {name: "Test"}
      allow(Attio::Record).to receive(:create).with(
        object: "people",
        values: values,
        api_key: "custom_key"
      )
      object.create_record(values, api_key: "custom_key")
    end
  end

  describe ".find_by_slug" do
    it "retrieves by slug first" do
      allow(described_class).to receive(:retrieve).with("people").and_return(
        described_class.new(object_attributes)
      )

      result = described_class.find_by_slug("people")
      expect(result.api_slug).to eq("people")
    end

    it "falls back to list when retrieve fails" do
      objects = [
        described_class.new(api_slug: "companies"),
        described_class.new(object_attributes),
        described_class.new(api_slug: "leads")
      ]

      allow(described_class).to receive(:retrieve).and_raise(Attio::NotFoundError.new("Not found"))
      allow(described_class).to receive(:list).and_return(objects)

      result = described_class.find_by_slug("people")
      expect(result.api_slug).to eq("people")
    end

    it "returns nil when not found in list" do
      allow(described_class).to receive(:retrieve).and_raise(Attio::NotFoundError.new("Not found"))
      allow(described_class).to receive(:list).and_return([])

      result = described_class.find_by_slug("nonexistent")
      expect(result).to be_nil
    end

    it "passes options to retrieve and list" do
      allow(described_class).to receive(:retrieve).with("people", api_key: "custom_key").and_raise(Attio::NotFoundError.new("Not found"))
      allow(described_class).to receive(:list).with(api_key: "custom_key").and_return([])

      described_class.find_by_slug("people", api_key: "custom_key")
    end
  end

  describe ".people" do
    it "finds the people object" do
      people_object = described_class.new(object_attributes)
      allow(described_class).to receive(:find_by_slug).with("people").and_return(people_object)

      result = described_class.people
      expect(result).to eq(people_object)
    end

    it "passes options" do
      expect(described_class).to receive(:find_by_slug).with("people", api_key: "custom_key")
      described_class.people(api_key: "custom_key")
    end
  end

  describe ".companies" do
    it "finds the companies object" do
      companies_object = described_class.new(api_slug: "companies")
      allow(described_class).to receive(:find_by_slug).with("companies").and_return(companies_object)

      result = described_class.companies
      expect(result).to eq(companies_object)
    end

    it "passes options" do
      expect(described_class).to receive(:find_by_slug).with("companies", api_key: "custom_key")
      described_class.companies(api_key: "custom_key")
    end
  end

  describe "API operations" do
    it "provides list operation" do
      expect(described_class).to respond_to(:list)
    end

    it "provides retrieve operation" do
      expect(described_class).to respond_to(:retrieve)
    end

    it "provides create operation" do
      expect(described_class).to respond_to(:create)
    end

    it "provides update operation" do
      expect(described_class).to respond_to(:update)
    end

    it "provides delete operation" do
      expect(described_class).to respond_to(:delete)
    end
  end
end
