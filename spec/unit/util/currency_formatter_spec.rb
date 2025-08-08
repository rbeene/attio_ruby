# frozen_string_literal: true

require "spec_helper"
require "attio/util/currency_formatter"

RSpec.describe Attio::Util::CurrencyFormatter do
  describe ".format" do
    context "with USD" do
      it "formats with dollar sign and two decimals" do
        expect(described_class.format(1234.56, "USD")).to eq("$1,234.56")
        expect(described_class.format(1000, "USD")).to eq("$1,000.00")
        expect(described_class.format(999.99, "USD")).to eq("$999.99")
        expect(described_class.format(1000000, "USD")).to eq("$1,000,000.00")
      end

      it "handles zero amounts" do
        expect(described_class.format(0, "USD")).to eq("$0.00")
      end

      it "handles fractional cents correctly" do
        expect(described_class.format(1234.567, "USD")).to eq("$1,234.57")
        expect(described_class.format(1234.564, "USD")).to eq("$1,234.56")
      end
    end

    context "with EUR" do
      it "formats with euro sign" do
        expect(described_class.format(1234.56, "EUR")).to eq("€1,234.56")
        expect(described_class.format(0, "EUR")).to eq("€0.00")
      end
    end

    context "with GBP" do
      it "formats with pound sign" do
        expect(described_class.format(1234.56, "GBP")).to eq("£1,234.56")
      end
    end

    context "with JPY" do
      it "formats without decimal places" do
        expect(described_class.format(100000, "JPY")).to eq("¥100,000")
        expect(described_class.format(1234567, "JPY")).to eq("¥1,234,567")
        expect(described_class.format(0, "JPY")).to eq("¥0")
      end

      it "rounds to whole number" do
        expect(described_class.format(1234.56, "JPY")).to eq("¥1,234")
        expect(described_class.format(1234.99, "JPY")).to eq("¥1,234")
      end
    end

    context "with KRW" do
      it "formats without decimal places" do
        expect(described_class.format(50000, "KRW")).to eq("₩50,000")
        expect(described_class.format(0, "KRW")).to eq("₩0")
      end
    end

    context "with unknown currency" do
      it "uses currency code with space" do
        expect(described_class.format(1234.56, "XYZ")).to eq("XYZ 1,234.56")
        expect(described_class.format(0, "ABC")).to eq("ABC 0.00")
      end
    end

    context "with custom options" do
      it "respects decimal_places option" do
        expect(described_class.format(1234.567, "USD", decimal_places: 3)).to eq("$1,234.567")
        expect(described_class.format(1234.5, "USD", decimal_places: 0)).to eq("$1,234")
      end

      it "respects separator options" do
        expect(described_class.format(1234.56, "USD", thousands_separator: " ", decimal_separator: ",")).to eq("$1 234,56")
        expect(described_class.format(1234567.89, "USD", thousands_separator: ".", decimal_separator: ",")).to eq("$1.234.567,89")
      end
    end

    context "with edge cases" do
      it "handles very large numbers" do
        expect(described_class.format(123456789012.34, "USD")).to eq("$123,456,789,012.34")
      end

      it "handles very small numbers" do
        expect(described_class.format(0.01, "USD")).to eq("$0.01")
        expect(described_class.format(0.99, "USD")).to eq("$0.99")
      end

      it "handles negative numbers" do
        expect(described_class.format(-1234.56, "USD")).to eq("$-1,234.56")
      end
    end
  end

  describe ".symbol_for" do
    it "returns correct symbols for known currencies" do
      expect(described_class.symbol_for("USD")).to eq("$")
      expect(described_class.symbol_for("EUR")).to eq("€")
      expect(described_class.symbol_for("GBP")).to eq("£")
      expect(described_class.symbol_for("JPY")).to eq("¥")
      expect(described_class.symbol_for("INR")).to eq("₹")
    end

    it "returns code with space for unknown currencies" do
      expect(described_class.symbol_for("XYZ")).to eq("XYZ ")
      expect(described_class.symbol_for("ABC")).to eq("ABC ")
    end

    it "handles lowercase input" do
      expect(described_class.symbol_for("usd")).to eq("$")
      expect(described_class.symbol_for("eur")).to eq("€")
    end
  end

  describe ".decimal_places_for" do
    it "returns 2 for most currencies" do
      expect(described_class.decimal_places_for("USD")).to eq(2)
      expect(described_class.decimal_places_for("EUR")).to eq(2)
      expect(described_class.decimal_places_for("GBP")).to eq(2)
    end

    it "returns 0 for no-decimal currencies" do
      expect(described_class.decimal_places_for("JPY")).to eq(0)
      expect(described_class.decimal_places_for("KRW")).to eq(0)
      expect(described_class.decimal_places_for("VND")).to eq(0)
      expect(described_class.decimal_places_for("IDR")).to eq(0)
      expect(described_class.decimal_places_for("CLP")).to eq(0)
    end

    it "returns 2 for unknown currencies" do
      expect(described_class.decimal_places_for("XYZ")).to eq(2)
    end
  end

  describe ".uses_decimals?" do
    it "returns true for decimal currencies" do
      expect(described_class.uses_decimals?("USD")).to be true
      expect(described_class.uses_decimals?("EUR")).to be true
      expect(described_class.uses_decimals?("GBP")).to be true
    end

    it "returns false for no-decimal currencies" do
      expect(described_class.uses_decimals?("JPY")).to be false
      expect(described_class.uses_decimals?("KRW")).to be false
    end
  end

  describe ".format_number" do
    it "returns formatted number without currency symbol" do
      expect(described_class.format_number(1234.56, "USD")).to eq("1,234.56")
      expect(described_class.format_number(100000, "JPY")).to eq("100,000")
      expect(described_class.format_number(1234.56, "EUR")).to eq("1,234.56")
    end

    it "works with unknown currencies" do
      expect(described_class.format_number(1234.56, "XYZ")).to eq("1,234.56")
    end

    it "respects options" do
      expect(described_class.format_number(1234.56, "USD", thousands_separator: " ")).to eq("1 234.56")
    end
  end
end
