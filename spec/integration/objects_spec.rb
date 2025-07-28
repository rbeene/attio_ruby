# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Object Integration", :integration do
  before do
    Attio.configure do |config|
      config.api_key = ENV["ATTIO_API_KEY"]
    end
  end

  describe "listing objects" do
    it "returns all workspace objects" do
      objects = Attio::Object.list

      expect(objects).to be_a(Attio::APIResource::ListObject)
      expect(objects.count).to be > 0

      # Standard objects should exist
      object_names = objects.map(&:api_slug)
      expect(object_names).to include("people", "companies")
    end
  end

  describe "retrieving an object" do
    it "gets object details by slug" do
      people_object = Attio::Object.retrieve("people")

      expect(people_object).to be_a(Attio::Object)
      expect(people_object.api_slug).to eq("people")
      expect(people_object.singular_noun).to eq("Person")
      expect(people_object.plural_noun).to eq("People")
    end

    it "raises error for non-existent object" do
      expect {
        Attio::Object.retrieve("non_existent_object")
      }.to raise_error(Attio::NotFoundError)
    end
  end
end
