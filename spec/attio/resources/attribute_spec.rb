# frozen_string_literal: true

require "spec_helper"

RSpec.describe Attio::Attribute do
  let(:attribute_id) { "attribute_123" }
  let(:object_id) { "object_456" }
  let(:attribute_data) do
    {
      "id" => {"attribute_id" => attribute_id, "object_id" => object_id},
      "api_slug" => "test_attribute",
      "name" => "Test Attribute",
      "description" => "A test attribute",
      "type" => "text",
      "is_required" => false,
      "is_unique" => false,
      "is_default_value_enabled" => true,
      "default_value" => "default",
      "options" => nil,
      "object_id" => object_id,
      "object_api_slug" => "companies",
      "parent_object_id" => nil,
      "created_by_actor" => {"type" => "user", "id" => "user_123"},
      "is_archived" => false,
      "archived_at" => nil,
      "title" => "Test Attribute"
    }
  end

  describe "TYPES" do
    it "includes all expected attribute types" do
      expect(described_class::TYPES).to include(
        "text", "number", "checkbox", "date", "timestamp",
        "rating", "currency", "status", "select", "multiselect",
        "email", "phone", "url", "user", "record_reference", "location"
      )
    end

    it "is frozen" do
      expect(described_class::TYPES).to be_frozen
    end
  end

  describe "TYPE_CONFIGS" do
    it "has configuration for all types" do
      described_class::TYPES.each do |type|
        expect(described_class::TYPE_CONFIGS).to have_key(type)
      end
    end

    it "defines correct configurations" do
      expect(described_class::TYPE_CONFIGS["text"]).to eq(
        {supports_default: true, supports_required: true}
      )
      expect(described_class::TYPE_CONFIGS["status"]).to eq(
        {requires_options: true}
      )
      expect(described_class::TYPE_CONFIGS["record_reference"]).to eq(
        {requires_target_object: true, supports_required: true}
      )
    end

    it "is frozen" do
      expect(described_class::TYPE_CONFIGS).to be_frozen
    end
  end

  describe ".resource_path" do
    it "returns 'attributes'" do
      expect(described_class.resource_path).to eq("attributes")
    end
  end

  describe "#initialize" do
    subject(:attribute_instance) { described_class.new(attribute_data) }

    it "sets identification attributes correctly" do
      expect(attribute_instance.id).to eq({"attribute_id" => attribute_id, "object_id" => object_id})
      expect(attribute_instance.api_slug).to eq("test_attribute")
      expect(attribute_instance.attio_object_id).to eq(object_id)
      expect(attribute_instance.object_api_slug).to eq("companies")
    end

    it "sets descriptive attributes correctly" do
      expect(attribute_instance.name).to eq("Test Attribute")
      expect(attribute_instance.title).to eq("Test Attribute")
      expect(attribute_instance.description).to eq("A test attribute")
      expect(attribute_instance.type).to eq("text")
    end

    it "sets configuration attributes correctly" do
      expect(attribute_instance.is_required).to be false
      expect(attribute_instance.is_unique).to be false
      expect(attribute_instance.is_default_value_enabled).to be true
      expect(attribute_instance.default_value).to eq("default")
      expect(attribute_instance.options).to be_nil
    end

    it "sets metadata attributes correctly" do
      expect(attribute_instance.parent_object_id).to be_nil
      expect(attribute_instance.created_by_actor).to eq("type" => "user", "id" => "user_123")
      expect(attribute_instance.is_archived).to be false
      expect(attribute_instance.archived_at).to be_nil
    end

    context "with archived attribute" do
      subject(:archived_attribute) { described_class.new(archived_data) }

      let(:archived_data) do
        attribute_data.merge(
          "is_archived" => true,
          "archived_at" => "2024-01-15T10:30:00Z"
        )
      end

      it "sets archived fields correctly" do
        expect(archived_attribute.is_archived).to be true
        expect(archived_attribute.archived_at).to be_a(Time)
        expect(archived_attribute.archived_at.iso8601).to eq("2024-01-15T10:30:00Z")
      end
    end
  end

  describe "#archive" do
    let(:attribute) { described_class.new(attribute_data) }
    let(:archived_response) do
      attribute_data.merge("is_archived" => true, "archived_at" => "2024-01-15T10:30:00Z")
    end

    context "when attribute is persisted" do
      before do
        allow(attribute).to receive(:persisted?).and_return(true)
      end

      it "archives the attribute" do
        stub_request(:post, "https://api.attio.com/v2/attributes/#{attribute_id}/archive")
          .to_return(
            status: 200,
            body: {data: archived_response}.to_json,
            headers: {"Content-Type" => "application/json"}
          )

        result = attribute.archive

        expect(result).to eq(attribute)
        expect(attribute.is_archived).to be true
        expect(attribute.archived_at).to be_a(Time)
      end
    end

    context "when attribute is not persisted" do
      before do
        allow(attribute).to receive(:persisted?).and_return(false)
      end

      it "raises InvalidRequestError" do
        expect { attribute.archive }.to raise_error(
          Attio::InvalidRequestError,
          "Cannot archive an attribute without an ID"
        )
      end
    end
  end

  describe "#unarchive" do
    let(:archived_data) do
      attribute_data.merge("is_archived" => true, "archived_at" => "2024-01-15T10:30:00Z")
    end
    let(:attribute) { described_class.new(archived_data) }
    let(:unarchived_response) do
      attribute_data.merge("is_archived" => false, "archived_at" => nil)
    end

    context "when attribute is persisted" do
      before do
        allow(attribute).to receive(:persisted?).and_return(true)
      end

      it "unarchives the attribute" do
        stub_request(:post, "https://api.attio.com/v2/attributes/#{attribute_id}/unarchive")
          .to_return(
            status: 200,
            body: {data: unarchived_response}.to_json,
            headers: {"Content-Type" => "application/json"}
          )

        result = attribute.unarchive

        expect(result).to eq(attribute)
        expect(attribute.is_archived).to be false
        expect(attribute.archived_at).to be_nil
      end
    end

    context "when attribute is not persisted" do
      before do
        allow(attribute).to receive(:persisted?).and_return(false)
      end

      it "raises InvalidRequestError" do
        expect { attribute.unarchive }.to raise_error(
          Attio::InvalidRequestError,
          "Cannot unarchive an attribute without an ID"
        )
      end
    end
  end

  describe "#archived?" do
    it "returns true when is_archived is true" do
      attribute = described_class.new(attribute_data.merge("is_archived" => true))
      expect(attribute.archived?).to be true
    end

    it "returns false when is_archived is false" do
      attribute = described_class.new(attribute_data.merge("is_archived" => false))
      expect(attribute.archived?).to be false
    end

    it "returns false when is_archived is nil" do
      attribute = described_class.new(attribute_data.merge("is_archived" => nil))
      expect(attribute.archived?).to be false
    end
  end

  describe "#required?" do
    it "returns true when is_required is true" do
      attribute = described_class.new(attribute_data.merge("is_required" => true))
      expect(attribute.required?).to be true
    end

    it "returns false when is_required is false" do
      attribute = described_class.new(attribute_data.merge("is_required" => false))
      expect(attribute.required?).to be false
    end
  end

  describe "#unique?" do
    it "returns true when is_unique is true" do
      attribute = described_class.new(attribute_data.merge("is_unique" => true))
      expect(attribute.unique?).to be true
    end

    it "returns false when is_unique is false" do
      attribute = described_class.new(attribute_data.merge("is_unique" => false))
      expect(attribute.unique?).to be false
    end
  end

  describe "#has_default?" do
    it "returns true when is_default_value_enabled is true" do
      attribute = described_class.new(attribute_data.merge("is_default_value_enabled" => true))
      expect(attribute.has_default?).to be true
    end

    it "returns false when is_default_value_enabled is false" do
      attribute = described_class.new(attribute_data.merge("is_default_value_enabled" => false))
      expect(attribute.has_default?).to be false
    end
  end

  describe "#to_h" do
    let(:attribute) { described_class.new(attribute_data) }

    it "includes all expected keys" do
      hash = attribute.to_h
      # Keys that should always be present
      required_keys = %i[
        api_slug name description type is_required is_unique
        is_default_value_enabled default_value object_id
        object_api_slug created_by_actor is_archived
      ]
      expect(hash.keys).to include(*required_keys)

      # Optional keys that may be removed by compact
      expect(hash).to have_key(:id) # ID comes from super
      expect(hash).to have_key(:title) # title comes from super
    end

    it "returns correct identification values" do
      hash = attribute.to_h
      expect(hash[:api_slug]).to eq("test_attribute")
      expect(hash[:name]).to eq("Test Attribute")
      expect(hash[:object_id]).to eq(object_id)
      expect(hash[:object_api_slug]).to eq("companies")
    end

    it "returns correct configuration values" do
      hash = attribute.to_h
      expect(hash[:type]).to eq("text")
      expect(hash[:is_required]).to be false
      expect(hash[:is_unique]).to be false
      expect(hash[:is_default_value_enabled]).to be true
      expect(hash[:default_value]).to eq("default")
    end

    it "returns correct description and options" do
      hash = attribute.to_h
      expect(hash[:description]).to eq("A test attribute")
      expect(hash[:options]).to be_nil
    end

    it "returns correct metadata values" do
      hash = attribute.to_h
      expect(hash[:parent_object_id]).to be_nil
      expect(hash[:created_by_actor]).to eq("type" => "user", "id" => "user_123")
      expect(hash[:is_archived]).to be false
      expect(hash[:archived_at]).to be_nil
    end

    context "with archived_at timestamp" do
      let(:archived_data) do
        attribute_data.merge("archived_at" => "2024-01-15T10:30:00Z")
      end
      let(:attribute) { described_class.new(archived_data) }

      it "formats archived_at as ISO8601" do
        expect(attribute.to_h[:archived_at]).to eq("2024-01-15T10:30:00Z")
      end
    end
  end

  describe "#resource_path" do
    let(:attribute) { described_class.new(attribute_data) }

    context "when persisted" do
      before do
        allow(attribute).to receive(:persisted?).and_return(true)
      end

      it "returns the correct path" do
        expect(attribute.resource_path).to eq("attributes/#{attribute_id}")
      end
    end

    context "when persisted with simple ID" do
      let(:simple_attribute) { described_class.new(attribute_data.merge("id" => "simple_123")) }

      before do
        allow(simple_attribute).to receive(:persisted?).and_return(true)
      end

      it "returns the correct path" do
        expect(simple_attribute.resource_path).to eq("attributes/simple_123")
      end
    end

    context "when not persisted" do
      before do
        allow(attribute).to receive(:persisted?).and_return(false)
      end

      it "raises InvalidRequestError" do
        expect { attribute.resource_path }.to raise_error(
          Attio::InvalidRequestError,
          "Cannot generate path without an ID"
        )
      end
    end
  end

  describe "#save" do
    let(:attribute) { described_class.new(attribute_data) }

    context "when persisted and changed" do
      before do
        allow(attribute).to receive(:persisted?).and_return(true)
        allow(attribute).to receive_messages(changed?: true, changed_attributes: {name: "Updated Name"})
      end

      it "calls update with the ID and changed attributes" do
        # Attribute ID is a nested hash, so we need to expect the extracted values
        allow(described_class).to receive(:update).with(
          attribute_id: "attribute_123",
          object: "object_456",
          name: "Updated Name"
        ).and_return(attribute)

        result = attribute.save
        expect(result).to eq(attribute)
      end
    end

    context "when persisted but not changed" do
      before do
        allow(attribute).to receive(:persisted?).and_return(true)
        allow(attribute).to receive(:changed?).and_return(false)
      end

      it "returns self without calling update" do
        expect(described_class).not_to receive(:update)
        result = attribute.save
        expect(result).to eq(attribute)
      end
    end

    context "when not persisted" do
      before do
        allow(attribute).to receive(:persisted?).and_return(false)
      end

      it "raises InvalidRequestError" do
        expect { attribute.save }.to raise_error(
          Attio::InvalidRequestError,
          "Cannot save a new attribute without 'object', 'name', and 'type' attributes"
        )
      end
    end
  end

  describe ".retrieve" do
    context "with simple ID" do
      it "retrieves the attribute" do
        stub_request(:get, "https://api.attio.com/v2/attributes/#{attribute_id}")
          .to_return(
            status: 200,
            body: {data: attribute_data}.to_json,
            headers: {"Content-Type" => "application/json"}
          )

        attribute = described_class.retrieve(attribute_id: attribute_id)

        expect(attribute).to be_a(described_class)
        expect(attribute.api_slug).to eq("test_attribute")
      end
    end

    context "with nested ID including object context" do
      let(:nested_id) { {"attribute_id" => attribute_id, "object_id" => object_id} }

      it "retrieves using object-scoped endpoint" do
        stub_request(:get, "https://api.attio.com/v2/objects/#{object_id}/attributes/#{attribute_id}")
          .to_return(
            status: 200,
            body: {data: attribute_data}.to_json,
            headers: {"Content-Type" => "application/json"}
          )

        attribute = described_class.retrieve(attribute_id: nested_id)

        expect(attribute).to be_a(described_class)
        expect(attribute.api_slug).to eq("test_attribute")
      end
    end

    context "with invalid ID" do
      it "raises ArgumentError for nil ID" do
        expect { described_class.retrieve(attribute_id: nil) }.to raise_error(ArgumentError)
      end

      it "raises ArgumentError for empty string ID" do
        expect { described_class.retrieve(attribute_id: "") }.to raise_error(ArgumentError)
      end
    end
  end

  describe ".update" do
    let(:update_params) { {name: "Updated Name", description: "Updated description"} }
    let(:updated_data) { attribute_data.merge("name" => "Updated Name", "description" => "Updated description") }

    context "with simple ID" do
      it "updates the attribute" do
        stub_request(:patch, "https://api.attio.com/v2/attributes/#{attribute_id}")
          .to_return(
            status: 200,
            body: {data: updated_data}.to_json,
            headers: {"Content-Type" => "application/json"}
          )

        attribute = described_class.update(attribute_id: attribute_id, **update_params)

        expect(attribute).to be_a(described_class)
        expect(attribute.name).to eq("Updated Name")
        expect(attribute.description).to eq("Updated description")
      end
    end

    context "with nested ID including object context" do
      let(:nested_id) { {"attribute_id" => attribute_id, "object_id" => object_id} }

      it "updates using object-scoped endpoint" do
        stub_request(:patch, "https://api.attio.com/v2/objects/#{object_id}/attributes/#{attribute_id}")
          .to_return(
            status: 200,
            body: {data: updated_data}.to_json,
            headers: {"Content-Type" => "application/json"}
          )

        attribute = described_class.update(attribute_id: nested_id, **update_params)

        expect(attribute).to be_a(described_class)
        expect(attribute.name).to eq("Updated Name")
      end
    end
  end

  describe ".list" do
    context "with object parameter" do
      it "lists attributes for the object" do
        stub_request(:get, "https://api.attio.com/v2/objects/companies/attributes")
          .to_return(
            status: 200,
            body: {
              "data" => [attribute_data],
              "meta" => {"count" => 1}
            }.to_json,
            headers: {"Content-Type" => "application/json"}
          )

        result = described_class.list(object: "companies")

        expect(result).to be_a(Attio::APIResource::ListObject)
        expect(result.data.first).to be_a(described_class)
        expect(result.data.first.api_slug).to eq("test_attribute")
      end
    end

    context "without object parameter" do
      it "raises ArgumentError" do
        expect { described_class.list }.to raise_error(ArgumentError)
      end
    end
  end

  describe ".create" do
    let(:create_params) do
      {
        object: "companies",
        name: "New Attribute",
        type: "text",
        description: "A new attribute",
        is_required: true
      }
    end

    it "creates a new attribute" do
      expected_body = {
        data: {
          title: "New Attribute",
          api_slug: "new_attribute",
          type: "text",
          description: "A new attribute",
          is_required: true,
          is_unique: false,
          is_multiselect: false,
          config: {}
        }
      }

      stub_request(:post, "https://api.attio.com/v2/objects/companies/attributes")
        .with(body: expected_body.to_json)
        .to_return(
          status: 200,
          body: {data: attribute_data}.to_json,
          headers: {"Content-Type" => "application/json"}
        )

      attribute = described_class.create(**create_params)

      expect(attribute).to be_a(described_class)
      expect(attribute.api_slug).to eq("test_attribute")
    end

    context "with invalid type" do
      it "raises ArgumentError" do
        expect {
          described_class.create(**create_params.merge(type: "invalid"))
        }.to raise_error(ArgumentError, /Invalid attribute type/)
      end
    end

    context "with type requiring options" do
      it "raises ArgumentError when options not provided" do
        expect {
          described_class.create(**create_params.merge(type: "status"))
        }.to raise_error(ArgumentError, /requires options/)
      end
    end

    context "with type requiring target object" do
      it "raises ArgumentError when target_object not provided" do
        expect {
          described_class.create(**create_params.merge(type: "record_reference"))
        }.to raise_error(ArgumentError, /requires target_object/)
      end
    end

    context "without object parameter" do
      it "raises ArgumentError" do
        expect {
          described_class.create(**create_params.except(:object))
        }.to raise_error(ArgumentError, /missing keyword: :object/)
      end
    end
  end

  describe ".for_object" do
    it "delegates to list with object parameter" do
      expect(described_class).to receive(:list).with(
        object: "companies", limit: 10
      )

      described_class.for_object("companies", limit: 10)
    end
  end

  describe ".prepare_params_for_update" do
    it "only includes updateable fields" do
      params = {
        name: "Updated",
        title: "Updated Title",
        description: "Updated desc",
        is_required: true,
        is_unique: false,
        default_value: "new default",
        options: ["opt1", "opt2"],
        type: "text", # Should be ignored
        api_slug: "new_slug" # Should be ignored
      }

      result = described_class.send(:prepare_params_for_update, params)

      expect(result[:data]).to include(
        name: "Updated",
        title: "Updated Title",
        description: "Updated desc",
        is_required: true,
        is_unique: false,
        default_value: "new default"
      )
      expect(result[:data]).not_to have_key(:type)
      expect(result[:data]).not_to have_key(:api_slug)
    end

    it "prepares options correctly" do
      params = {options: ["Option 1", {title: "Option 2", value: "opt2"}]}
      result = described_class.send(:prepare_params_for_update, params)

      expect(result[:data][:options]).to eq([
        {title: "Option 1"},
        {title: "Option 2", value: "opt2"}
      ])
    end
  end

  describe ".prepare_options" do
    it "handles nil options" do
      expect(described_class.send(:prepare_options, nil)).to be_nil
    end

    it "converts string array to hash array" do
      result = described_class.send(:prepare_options, ["Option 1", "Option 2"])
      expect(result).to eq([
        {title: "Option 1"},
        {title: "Option 2"}
      ])
    end

    it "preserves hash options" do
      options = [{title: "Opt 1", value: "1"}, {title: "Opt 2", value: "2"}]
      result = described_class.send(:prepare_options, options)
      expect(result).to eq(options)
    end

    it "converts other types to string" do
      result = described_class.send(:prepare_options, [123, :symbol])
      expect(result).to eq([
        {title: "123"},
        {title: "symbol"}
      ])
    end

    it "returns non-array options as-is" do
      expect(described_class.send(:prepare_options, "string")).to eq("string")
      expect(described_class.send(:prepare_options, {foo: "bar"})).to eq({foo: "bar"})
    end
  end

  describe ".validate_type_config!" do
    it "validates options for status type" do
      expect {
        described_class.send(:validate_type_config!, {type: "status", options: []})
      }.to raise_error(ArgumentError, /requires options/)

      expect {
        described_class.send(:validate_type_config!, {type: "status", options: ["Active"]})
      }.not_to raise_error
    end

    it "validates target_object for record_reference type" do
      expect {
        described_class.send(:validate_type_config!, {type: "record_reference"})
      }.to raise_error(ArgumentError, /requires target_object/)

      expect {
        described_class.send(:validate_type_config!, {type: "record_reference", target_object: "companies"})
      }.not_to raise_error
    end

    it "validates unsupported unique constraint" do
      expect {
        described_class.send(:validate_type_config!, {type: "checkbox", is_unique: true})
      }.to raise_error(ArgumentError, /does not support unique constraint/)
    end

    it "validates unsupported required constraint" do
      expect {
        described_class.send(:validate_type_config!, {type: "checkbox", is_required: true})
      }.to raise_error(ArgumentError, /does not support required constraint/)
    end

    it "validates unsupported default value" do
      expect {
        described_class.send(:validate_type_config!, {type: "multiselect", options: ["opt1"], is_default_value_enabled: true})
      }.to raise_error(ArgumentError, /does not support default values/)
    end
  end
end
