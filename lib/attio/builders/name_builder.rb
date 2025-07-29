# frozen_string_literal: true

module Attio
  module Builders
    # Builder class for constructing person name attributes
    # Provides a fluent interface for building complex name structures
    #
    # @example Basic usage
    #   name = Attio::Builders::NameBuilder.new
    #     .first("John")
    #     .last("Doe")
    #     .build
    #   # => [{first_name: "John", last_name: "Doe", full_name: "John Doe"}]
    #
    # @example With middle name and suffix
    #   name = Attio::Builders::NameBuilder.new
    #     .first("John")
    #     .middle("Michael")
    #     .last("Doe")
    #     .suffix("Jr.")
    #     .build
    class NameBuilder
      def initialize
        @name_data = {}
      end

      # Set the first name
      # @param name [String] The first name
      # @return [NameBuilder] self for chaining
      def first(name)
        @name_data[:first_name] = name
        self
      end

      # Set the middle name
      # @param name [String] The middle name
      # @return [NameBuilder] self for chaining
      def middle(name)
        @name_data[:middle_name] = name
        self
      end

      # Set the last name
      # @param name [String] The last name
      # @return [NameBuilder] self for chaining
      def last(name)
        @name_data[:last_name] = name
        self
      end

      # Set the prefix (e.g., "Dr.", "Mr.", "Ms.")
      # @param prefix [String] The name prefix
      # @return [NameBuilder] self for chaining
      def prefix(prefix)
        @name_data[:prefix] = prefix
        self
      end

      # Set the suffix (e.g., "Jr.", "III", "PhD")
      # @param suffix [String] The name suffix
      # @return [NameBuilder] self for chaining
      def suffix(suffix)
        @name_data[:suffix] = suffix
        self
      end

      # Set a custom full name (overrides auto-generation)
      # @param name [String] The full name
      # @return [NameBuilder] self for chaining
      def full(name)
        @name_data[:full_name] = name
        self
      end

      # Build the name array structure expected by Attio
      # @return [Array<Hash>] The name data in Attio's expected format
      def build
        # Generate full name if not explicitly set
        unless @name_data[:full_name]
          parts = []
          parts << @name_data[:prefix] if @name_data[:prefix]
          parts << @name_data[:first_name] if @name_data[:first_name]
          parts << @name_data[:middle_name] if @name_data[:middle_name]
          parts << @name_data[:last_name] if @name_data[:last_name]
          parts << @name_data[:suffix] if @name_data[:suffix]

          @name_data[:full_name] = parts.join(" ") unless parts.empty?
        end

        # Return as array with single hash (Attio's expected format)
        [@name_data]
      end

      # Parse a full name string into components
      # This is a simple parser and may not handle all edge cases
      # @param full_name [String] The full name to parse
      # @return [NameBuilder] self for chaining
      def parse(full_name)
        return self unless full_name

        parts = full_name.strip.split(/\s+/)

        # Simple parsing logic - can be enhanced
        case parts.length
        when 1
          @name_data[:first_name] = parts[0]
        when 2
          @name_data[:first_name] = parts[0]
          @name_data[:last_name] = parts[1]
        when 3
          # Check for common prefixes
          if %w[Dr Mr Mrs Ms Miss Prof].include?(parts[0])
            @name_data[:prefix] = parts[0]
            @name_data[:first_name] = parts[1]
            @name_data[:last_name] = parts[2]
          # Check for common suffixes
          elsif %w[Jr Sr III II PhD MD].include?(parts[2])
            @name_data[:first_name] = parts[0]
            @name_data[:last_name] = parts[1]
            @name_data[:suffix] = parts[2]
          else
            # Assume first middle last
            @name_data[:first_name] = parts[0]
            @name_data[:middle_name] = parts[1]
            @name_data[:last_name] = parts[2]
          end
        else
          # For 4+ parts, make educated guesses
          # This is simplified - real implementation would be more sophisticated
          if %w[Dr Mr Mrs Ms Miss Prof].include?(parts[0])
            @name_data[:prefix] = parts.shift
          end

          if parts.length > 2 && %w[Jr Sr III II PhD MD].include?(parts.last)
            @name_data[:suffix] = parts.pop
          end

          if parts.length >= 3
            @name_data[:first_name] = parts[0]
            @name_data[:last_name] = parts[-1]
            @name_data[:middle_name] = parts[1..-2].join(" ") if parts.length > 2
          elsif parts.length == 2
            @name_data[:first_name] = parts[0]
            @name_data[:last_name] = parts[1]
          elsif parts.length == 1
            @name_data[:first_name] = parts[0]
          end
        end

        @name_data[:full_name] = full_name
        self
      end

      # Create a name builder from various input formats
      # @param input [String, Hash, NameBuilder] The input to convert
      # @return [Array<Hash>] The name data in Attio's expected format
      def self.build(input)
        case input
        when String
          new.parse(input).build
        when Hash
          builder = new
          builder.first(input[:first] || input[:first_name]) if input[:first] || input[:first_name]
          builder.middle(input[:middle] || input[:middle_name]) if input[:middle] || input[:middle_name]
          builder.last(input[:last] || input[:last_name]) if input[:last] || input[:last_name]
          builder.prefix(input[:prefix]) if input[:prefix]
          builder.suffix(input[:suffix]) if input[:suffix]
          builder.full(input[:full] || input[:full_name]) if input[:full] || input[:full_name]
          builder.build
        when NameBuilder
          input.build
        when Array
          # If it's already in the right format, return it
          input
        else
          raise ArgumentError, "Invalid input type for NameBuilder: #{input.class}"
        end
      end
    end
  end
end
