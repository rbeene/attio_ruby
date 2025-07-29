# frozen_string_literal: true

require "spec_helper"

RSpec.describe Attio::Attribute do
  let(:attribute_attributes) do
    {
      id: {"attribute_id" => "attr_123"},
      api_slug: "custom_field",
      name: "Custom Field",
      description: "A custom field for testing",
      type: "text",
      is_required: true,
      is_unique: false,
      is_default_value_enabled: true,
      default_value: "Default text",
      options: nil,
      object_id: "obj_123",
      object_api_slug: "people",
      parent_object_id: "obj_123",
      created_by_actor: {
        type: "user",
        id: "usr_123"
      },
      is_archived: false,
      archived_at: nil,
      title: "Custom Field"
    }
  end

  describe "#initialize" do
    it "sets attributes correctly" do
      attribute = described_class.new(attribute_attributes)

      expect(attribute.api_slug).to eq("custom_field")
      expect(attribute.name).to eq("Custom Field")
      expect(attribute.description).to eq("A custom field for testing")
      expect(attribute.type).to eq("text")
      expect(attribute.is_required).to be true
      expect(attribute.is_unique).to be false
      expect(attribute.is_default_value_enabled).to be true
      expect(attribute.default_value).to eq("Default text")
      expect(attribute.attio_object_id).to eq("obj_123")
      expect(attribute.object_api_slug).to eq("people")
      expect(attribute.parent_object_id).to eq("obj_123")
      expect(attribute.created_by_actor).to eq({type: "user", id: "usr_123"})
      expect(attribute.is_archived).to be false
      expect(attribute.archived_at).to be_nil
      expect(attribute.title).to eq("Custom Field")
    end

    it "handles string keys" do
      string_attrs = {
        "id" => {"attribute_id" => "attr_456"},
        "api_slug" => "another_field",
        "name" => "Another Field",
        "type" => "number",
        "is_required" => false
      }

      attribute = described_class.new(string_attrs)
      expect(attribute.api_slug).to eq("another_field")
      expect(attribute.name).to eq("Another Field")
      expect(attribute.type).to eq("number")
      expect(attribute.is_required).to be false
    end

    it "defaults is_archived to false" do
      attribute = described_class.new({})
      expect(attribute.is_archived).to be false
    end
  end

  describe ".resource_path" do
    it "returns the correct path" do
      expect(described_class.resource_path).to eq("attributes")
    end
  end

  describe "#resource_path" do
    it "returns the correct path for a persisted attribute" do
      attribute = described_class.new(attribute_attributes)
      expect(attribute.resource_path).to eq("attributes/attr_123")
    end

    it "extracts attribute_id from nested hash" do
      attribute = described_class.new(id: {"attribute_id" => "attr_789"})
      expect(attribute.resource_path).to eq("attributes/attr_789")
    end

    it "handles simple ID format" do
      attribute = described_class.new(id: "attr_simple")
      expect(attribute.resource_path).to eq("attributes/attr_simple")
    end

    it "raises error for unpersisted attribute" do
      attribute = described_class.new({})
      expect { attribute.resource_path }.to raise_error(
        Attio::InvalidRequestError,
        "Cannot generate path without an ID"
      )
    end
  end

  describe "#archive" do
    let(:attribute) { described_class.new(attribute_attributes) }

    it "archives the attribute" do
      archived_response = attribute_attributes.merge(is_archived: true, archived_at: Time.now.iso8601)

      allow(described_class).to receive(:execute_request).with(
        :POST,
        "attributes/attr_123/archive",
        {},
        {}
      ).and_return({data: archived_response})

      result = attribute.archive
      expect(result).to eq(attribute)
    end

    it "raises error for unpersisted attribute" do
      unpersisted = described_class.new({})
      expect { unpersisted.archive }.to raise_error(
        Attio::InvalidRequestError,
        "Cannot archive an attribute without an ID"
      )
    end

    it "passes options" do
      allow(described_class).to receive(:execute_request).with(
        :POST,
        "attributes/attr_123/archive",
        {},
        {api_key: "custom_key"}
      ).and_return({data: attribute_attributes})

      attribute.archive(api_key: "custom_key")
    end
  end

  describe "#unarchive" do
    let(:attribute) { described_class.new(attribute_attributes.merge(is_archived: true)) }

    it "unarchives the attribute" do
      unarchived_response = attribute_attributes.merge(is_archived: false, archived_at: nil)

      allow(described_class).to receive(:execute_request).with(
        :POST,
        "attributes/attr_123/unarchive",
        {},
        {}
      ).and_return({data: unarchived_response})

      result = attribute.unarchive
      expect(result).to eq(attribute)
    end

    it "raises error for unpersisted attribute" do
      unpersisted = described_class.new({})
      expect { unpersisted.unarchive }.to raise_error(
        Attio::InvalidRequestError,
        "Cannot unarchive an attribute without an ID"
      )
    end
  end

  describe "#archived?" do
    it "returns true when archived" do
      attribute = described_class.new(is_archived: true)
      expect(attribute.archived?).to be true
    end

    it "returns false when not archived" do
      attribute = described_class.new(is_archived: false)
      expect(attribute.archived?).to be false
    end
  end

  describe "#required?" do
    it "returns true when required" do
      attribute = described_class.new(is_required: true)
      expect(attribute.required?).to be true
    end

    it "returns false when not required" do
      attribute = described_class.new(is_required: false)
      expect(attribute.required?).to be false
    end
  end

  describe "#unique?" do
    it "returns true when unique" do
      attribute = described_class.new(is_unique: true)
      expect(attribute.unique?).to be true
    end

    it "returns false when not unique" do
      attribute = described_class.new(is_unique: false)
      expect(attribute.unique?).to be false
    end
  end

  describe "#has_default?" do
    it "returns true when default is enabled" do
      attribute = described_class.new(is_default_value_enabled: true)
      expect(attribute.has_default?).to be true
    end

    it "returns false when default is not enabled" do
      attribute = described_class.new(is_default_value_enabled: false)
      expect(attribute.has_default?).to be false
    end
  end

  describe "#save" do
    it "updates the attribute when changed" do
      attribute = described_class.new(attribute_attributes)
      attribute.name = "Updated Name"

      expect(described_class).to receive(:update).with(
        {"attribute_id" => "attr_123"},
        {name: "Updated Name"}
      )

      attribute.save
    end

    it "returns self if nothing changed" do
      attribute = described_class.new(attribute_attributes)
      expect(described_class).not_to receive(:update)
      expect(attribute.save).to eq(attribute)
    end

    it "raises error for unpersisted attribute" do
      unpersisted = described_class.new({})
      expect { unpersisted.save }.to raise_error(
        Attio::InvalidRequestError,
        "Cannot save an attribute without an ID"
      )
    end
  end

  describe "#to_h" do
    it "includes all attribute fields" do
      attribute = described_class.new(attribute_attributes)
      hash = attribute.to_h

      expect(hash).to include(
        api_slug: "custom_field",
        name: "Custom Field",
        description: "A custom field for testing",
        type: "text",
        is_required: true,
        is_unique: false,
        is_default_value_enabled: true,
        default_value: "Default text",
        object_id: "obj_123",
        object_api_slug: "people",
        parent_object_id: "obj_123",
        created_by_actor: {type: "user", id: "usr_123"},
        is_archived: false
      )
    end

    it "compacts nil values" do
      attribute = described_class.new({})
      hash = attribute.to_h

      expect(hash).not_to have_key(:archived_at)
      expect(hash).not_to have_key(:options)
    end

    it "formats archived_at as ISO8601" do
      timestamp = Time.parse("2023-01-15T10:30:00Z")
      attribute = described_class.new(archived_at: timestamp)

      expect(attribute.to_h[:archived_at]).to eq("2023-01-15T10:30:00Z")
    end
  end

  describe ".retrieve" do
    it "retrieves using object context when available" do
      allow(described_class).to receive(:execute_request).with(
        :GET,
        "objects/obj_123/attributes/attr_123",
        {},
        {}
      ).and_return({"data" => attribute_attributes})

      result = described_class.retrieve({"attribute_id" => "attr_123", "object_id" => "obj_123"})
      expect(result).to be_a(described_class)
    end

    it "falls back to regular endpoint without object context" do
      allow(described_class).to receive(:execute_request).with(
        :GET,
        "attributes/attr_simple",
        {},
        {}
      ).and_return({"data" => attribute_attributes})

      result = described_class.retrieve("attr_simple")
      expect(result).to be_a(described_class)
    end

    it "validates ID" do
      expect { described_class.retrieve(nil) }.to raise_error(ArgumentError)
    end
  end

  describe ".update" do
    it "updates using object context when available" do
      allow(described_class).to receive(:execute_request).with(
        :PATCH,
        "objects/obj_123/attributes/attr_123",
        {data: {name: "Updated"}},
        {}
      ).and_return({"data" => attribute_attributes})

      result = described_class.update(
        {"attribute_id" => "attr_123", "object_id" => "obj_123"},
        {name: "Updated"}
      )
      expect(result).to be_a(described_class)
    end

    it "falls back to regular endpoint without object context" do
      allow(described_class).to receive(:execute_request).with(
        :PATCH,
        "attributes/attr_simple",
        {data: {name: "Updated"}},
        {}
      ).and_return({"data" => attribute_attributes})

      result = described_class.update("attr_simple", {name: "Updated"})
      expect(result).to be_a(described_class)
    end

    it "only includes updateable fields" do
      allow(described_class).to receive(:execute_request).with(
        :PATCH,
        "attributes/attr_123",
        {data: {name: "New Name", description: "New Desc"}},
        {}
      ).and_return({"data" => attribute_attributes})

      described_class.update(
        "attr_123",
        {name: "New Name", description: "New Desc", type: "number", api_slug: "ignored"}
      )
    end
  end

  describe ".list" do
    it "requires an object parameter" do
      expect {
        described_class.list
      }.to raise_error(ArgumentError, /must be listed for a specific object/)
    end

    it "lists attributes for a specific object" do
      allow(described_class).to receive(:execute_request).with(
        :GET,
        "objects/people/attributes",
        {},
        {}
      ).and_return({"data" => [attribute_attributes]})

      result = described_class.list({object: "people"})
      expect(result).to be_a(Attio::APIResource::ListObject)
    end

    it "validates object identifier" do
      expect {
        described_class.list({object: nil})
      }.to raise_error(ArgumentError, /must be listed for a specific object/)

      expect {
        described_class.list({object: ""})
      }.to raise_error(ArgumentError, "Object identifier is required")
    end
  end

  describe ".create" do
    it "creates an attribute for an object" do
      params = {
        object: "people",
        name: "New Field",
        type: "text",
        description: "A new field"
      }

      allow(described_class).to receive(:execute_request).with(
        :POST,
        "objects/people/attributes",
        {
          data: {
            title: "New Field",
            api_slug: "new_field",
            type: "text",
            description: "A new field",
            is_required: false,
            is_unique: false,
            is_multiselect: false,
            config: {}
          }
        },
        {}
      ).and_return({"data" => attribute_attributes})

      result = described_class.create(params)
      expect(result).to be_a(described_class)
    end

    it "validates object identifier" do
      expect {
        described_class.create({name: "Field", type: "text"})
      }.to raise_error(ArgumentError, "Object identifier is required")
    end

    it "validates attribute type" do
      expect {
        described_class.create({object: "people", name: "Field", type: nil})
      }.to raise_error(ArgumentError, "Attribute type is required")

      expect {
        described_class.create({object: "people", name: "Field", type: "invalid"})
      }.to raise_error(ArgumentError, /Invalid attribute type/)
    end

    it "validates type-specific requirements" do
      expect {
        described_class.create({object: "people", name: "Status", type: "status"})
      }.to raise_error(ArgumentError, "Attribute type 'status' requires options")

      expect {
        described_class.create({object: "people", name: "Ref", type: "record_reference"})
      }.to raise_error(ArgumentError, "Attribute type 'record_reference' requires target_object")
    end

    it "validates unsupported features" do
      expect {
        described_class.create({
          object: "people",
          name: "Checkbox",
          type: "checkbox",
          is_unique: true
        })
      }.to raise_error(ArgumentError, "Attribute type 'checkbox' does not support unique constraint")
    end

    it "generates api_slug from name if not provided" do
      allow(described_class).to receive(:execute_request) do |_, _, params, _|
        expect(params[:data][:api_slug]).to eq("my_custom_field")
        {"data" => attribute_attributes}
      end

      described_class.create({
        object: "people",
        name: "My Custom Field",
        type: "text"
      })
    end
  end

  describe ".for_object" do
    it "lists attributes for a specific object" do
      expect(described_class).to receive(:list).with(
        {limit: 10, object: "people"}
      )

      described_class.for_object("people", {limit: 10})
    end

    it "passes options" do
      expect(described_class).to receive(:list).with(
        {object: "companies"},
        api_key: "custom_key"
      )

      described_class.for_object("companies", {}, api_key: "custom_key")
    end
  end

  describe "TYPES constant" do
    it "includes all valid attribute types" do
      expect(described_class::TYPES).to include("text", "number", "checkbox", "date")
      expect(described_class::TYPES).to include("email", "phone", "url", "record_reference")
      expect(described_class::TYPES).to be_frozen
    end
  end

  describe "TYPE_CONFIGS constant" do
    it "defines configurations for each type" do
      expect(described_class::TYPE_CONFIGS["text"]).to eq({
        supports_default: true,
        supports_required: true
      })

      expect(described_class::TYPE_CONFIGS["status"]).to eq({
        requires_options: true
      })

      expect(described_class::TYPE_CONFIGS["record_reference"]).to eq({
        requires_target_object: true,
        supports_required: true
      })
    end

    it "is frozen" do
      expect(described_class::TYPE_CONFIGS).to be_frozen
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

    it "does not provide delete operation" do
      expect(described_class).not_to respond_to(:delete)
    end
  end
end
