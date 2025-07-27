# frozen_string_literal: true

RSpec.describe Attio do
  it "has a version number" do
    expect(Attio::VERSION).not_to be_nil
  end

  it "can be configured" do
    described_class.configure do |config|
      config.api_key = "test_key"
    end
    expect(described_class.api_key).to eq("test_key")
  end
end
