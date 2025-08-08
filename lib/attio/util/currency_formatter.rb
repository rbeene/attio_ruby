# frozen_string_literal: true

module Attio
  module Util
    # Utility class for formatting currency amounts
    class CurrencyFormatter
      # Map of currency codes to their symbols
      CURRENCY_SYMBOLS = {
        "USD" => "$",
        "EUR" => "€",
        "GBP" => "£",
        "JPY" => "¥",
        "CNY" => "¥",
        "INR" => "₹",
        "KRW" => "₩",
        "CAD" => "$",
        "AUD" => "$",
        "CHF" => "CHF ",
        "SEK" => "SEK ",
        "NOK" => "NOK ",
        "DKK" => "DKK ",
        "PLN" => "zł",
        "BRL" => "R$",
        "MXN" => "$",
        "NZD" => "$",
        "SGD" => "$",
        "HKD" => "$",
        "ZAR" => "R",
        "THB" => "฿",
        "PHP" => "₱",
        "IDR" => "Rp",
        "MYR" => "RM",
        "VND" => "₫",
        "TRY" => "₺",
        "RUB" => "₽",
        "UAH" => "₴",
        "ILS" => "₪",
        "AED" => "د.إ",
        "SAR" => "﷼",
        "CLP" => "$",
        "COP" => "$",
        "PEN" => "S/",
        "ARS" => "$"
      }.freeze
      
      # Currencies that typically don't use decimal places
      NO_DECIMAL_CURRENCIES = %w[JPY KRW VND IDR CLP].freeze
      
      class << self
        # Format an amount with the appropriate currency symbol
        # @param amount [Numeric] The amount to format
        # @param currency_code [String] The ISO 4217 currency code
        # @param options [Hash] Formatting options
        # @option options [Integer] :decimal_places Number of decimal places (auto-determined by default)
        # @option options [String] :thousands_separator Character for thousands separation (default: ",")
        # @option options [String] :decimal_separator Character for decimal separation (default: ".")
        # @return [String] The formatted currency string
        def format(amount, currency_code = "USD", options = {})
          currency_code = currency_code.to_s.upcase
          symbol = symbol_for(currency_code)
          
          # Determine decimal places
          decimal_places = options[:decimal_places] || decimal_places_for(currency_code)
          thousands_sep = options[:thousands_separator] || ","
          decimal_sep = options[:decimal_separator] || "."
          
          # Handle zero amounts
          if amount == 0
            if decimal_places > 0
              return "#{symbol}0#{decimal_sep}#{"0" * decimal_places}"
            else
              return "#{symbol}0"
            end
          end
          
          # Handle negative amounts
          negative = amount < 0
          abs_amount = amount.abs
          
          # Format the amount
          if decimal_places == 0
            # No decimal places
            formatted = format_with_separators(abs_amount.to_i, thousands_sep)
            formatted = "-#{formatted}" if negative
            "#{symbol}#{formatted}"
          else
            # With decimal places
            whole = abs_amount.to_i
            decimal = ((abs_amount - whole) * (10 ** decimal_places)).round
            formatted_whole = format_with_separators(whole, thousands_sep)
            formatted_whole = "-#{formatted_whole}" if negative
            formatted_decimal = decimal.to_s.rjust(decimal_places, "0")
            "#{symbol}#{formatted_whole}#{decimal_sep}#{formatted_decimal}"
          end
        end
        
        # Get the currency symbol for a given code
        # @param currency_code [String] The ISO 4217 currency code
        # @return [String] The currency symbol or code with space
        def symbol_for(currency_code)
          currency_code = currency_code.to_s.upcase
          CURRENCY_SYMBOLS[currency_code] || "#{currency_code} "
        end
        
        # Determine the number of decimal places for a currency
        # @param currency_code [String] The ISO 4217 currency code
        # @return [Integer] Number of decimal places
        def decimal_places_for(currency_code)
          currency_code = currency_code.to_s.upcase
          NO_DECIMAL_CURRENCIES.include?(currency_code) ? 0 : 2
        end
        
        # Check if a currency typically uses decimal places
        # @param currency_code [String] The ISO 4217 currency code
        # @return [Boolean] True if the currency uses decimals
        def uses_decimals?(currency_code)
          decimal_places_for(currency_code) > 0
        end
        
        # Format just the numeric part without currency symbol
        # @param amount [Numeric] The amount to format
        # @param currency_code [String] The ISO 4217 currency code
        # @param options [Hash] Formatting options (same as format method)
        # @return [String] The formatted number without currency symbol
        def format_number(amount, currency_code = "USD", options = {})
          result = format(amount, currency_code, options)
          symbol = symbol_for(currency_code)
          result.sub(/^#{Regexp.escape(symbol)}/, "")
        end
        
        private
        
        # Add thousands separators to a number
        # @param number [Integer] The number to format
        # @param separator [String] The separator character
        # @return [String] The formatted number
        def format_with_separators(number, separator)
          number.to_s.reverse.gsub(/(\d{3})(?=\d)/, "\\1#{separator}").reverse
        end
      end
    end
  end
end