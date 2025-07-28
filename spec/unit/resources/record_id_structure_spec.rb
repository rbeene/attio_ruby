# frozen_string_literal: true

require "spec_helper"

RSpec.describe Attio::Record do
  describe "when accessing record IDs from list" do
    it "reproduces the undefined method '[]' for nil error when ID is nil" do
      # This simulates what happens when a record doesn't have an ID
      record_data = {
        "values" => {
          "name" => [{"value" => "Test Person"}]
        }
        # Note: no "id" field
      }

      record = described_class.new(record_data)

      # This is what the OAuth example is trying to do:
      # people.first[:id][:record_id]
      # But when [:id] returns nil, calling [:record_id] on nil causes the error

      expect(record[:id]).to be_nil
      expect { record[:id][:record_id] }.to raise_error(NoMethodError, /undefined method .\[\].+ for nil/)
    end

    it "shows what happens when using bracket notation on records" do
      record_data = {
        "id" => {
          "workspace_id" => "workspace_123",
          "object_id" => "object_456",
          "record_id" => "record_789"
        },
        "values" => {
          "name" => [{"value" => "Test Person"}]
        }
      }

      record = described_class.new(record_data)

      # Using bracket notation returns nil because :id is not in @attributes
      expect(record[:id]).to be_nil

      # The correct way is to use the id method
      expect(record.id).to eq({
        "workspace_id" => "workspace_123",
        "object_id" => "object_456",
        "record_id" => "record_789"
      })
      expect(record.id["record_id"]).to eq("record_789")
    end

    it "demonstrates the bug in the OAuth example" do
      # Simulate what Record.list returns
      people = [
        described_class.new({
          "id" => {
            "workspace_id" => "workspace_123",
            "object_id" => "object_456",
            "record_id" => "record_789"
          },
          "values" => {
            "name" => [{"value" => "Test Person"}]
          }
        })
      ]

      # This is what the OAuth example does
      first_person = people.first

      # This returns nil because :id is not an attribute
      expect(first_person[:id]).to be_nil

      # So this causes the error
      expect { first_person[:id][:record_id] }.to raise_error(NoMethodError)

      # The fix is to use the id method instead
      expect(first_person.id["record_id"]).to eq("record_789")
    end
  end
end
