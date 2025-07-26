# frozen_string_literal: true

module Attio
  # Base class for all API resources
  # Provides standard CRUD operations in a clean, Ruby-like way
  class APIResource < Resources::Base
    class << self
      # Define which operations this resource supports
      # Example: api_operations :list, :create, :retrieve, :update, :delete
      def api_operations(*operations)
        @supported_operations = operations
        
        operations.each do |operation|
          case operation
          when :list
            define_list_operation
          when :create
            define_create_operation
          when :retrieve
            define_retrieve_operation
          when :update
            define_update_operation
          when :delete
            define_delete_operation
          else
            raise ArgumentError, "Unknown operation: #{operation}"
          end
        end
      end

      def supported_operations
        @supported_operations || []
      end

      private

      def define_list_operation
        singleton_class.class_eval do
          def list(params = {}, **opts)
            response = execute_request(:GET, resource_path, params, opts)
            
            ListObject.new(response, self, params, opts)
          end
        end
      end

      def define_create_operation
        singleton_class.class_eval do
          def create(attributes = {}, **opts)
            params = prepare_params_for_create(attributes)
            
            response = execute_request(:POST, resource_path, params, opts)
            
            new(response[:data] || response, opts)
          end

          private

          def prepare_params_for_create(params)
            params # Override in subclasses if needed
          end
        end
      end

      def define_retrieve_operation
        singleton_class.class_eval do
          def retrieve(id, **opts)
            validate_id!(id)
            
            response = execute_request(:GET, "#{resource_path}/#{id}", {}, opts)
            
            new(response[:data] || response, opts)
          end

          alias_method :get, :retrieve
          alias_method :find, :retrieve
        end
      end

      def define_update_operation
        singleton_class.class_eval do
          def update(id, attributes = {}, **opts)
            validate_id!(id)
            
            response = execute_request(:PATCH, "#{resource_path}/#{id}", attributes, opts)
            
            new(response[:data] || response, opts)
          end
        end

        # Add instance methods for update
        class_eval do
          def update_attributes(attributes)
            attributes.each { |key, value| self[key] = value }
            save
          end

          def save(**opts)
            if persisted?
              response = self.class.send(:execute_request, :PATCH, resource_path, changed_attributes, opts)
              
              update_from(response[:data] || response)
              reset_changes!
              self
            else
              raise InvalidRequestError, "Cannot save a new record - use create instead"
            end
          end
        end
      end

      def define_delete_operation
        singleton_class.class_eval do
          def delete(id, **opts)
            validate_id!(id)
            
            execute_request(:DELETE, "#{resource_path}/#{id}", {}, opts)
            
            true
          end
        end

        # Add instance methods for delete
        class_eval do
          def destroy(**opts)
            raise InvalidRequestError, "Cannot delete without an ID" unless persisted?
            
            self.class.delete(id, **opts)
            freeze
            true
          end

          alias_method :delete, :destroy
        end
      end

      # Common methods used by operations
      def execute_request(method, path, params, opts)
        client = Attio.client(api_key: opts[:api_key])
        
        case method
        when :GET
          client.get(path, params)
        when :POST
          client.post(path, params)
        when :PUT
          client.put(path, params)
        when :PATCH
          client.patch(path, params)
        when :DELETE
          client.delete(path)
        else
          raise ArgumentError, "Unsupported method: #{method}"
        end
      end

      def validate_id!(id)
        raise ArgumentError, "ID is required" if id.nil? || id.to_s.empty?
      end
    end

    # Instance methods available on all API resources

    def persisted?
      !id.nil?
    end

    def resource_path
      raise InvalidRequestError, "Cannot generate path without an ID" unless persisted?
      "#{self.class.resource_path}/#{id}"
    end

    private

    def update_from(attributes)
      normalized = normalize_attributes(attributes)
      
      # Update instance variables for known attributes
      normalized.each do |key, value|
        if respond_to?("#{key}=")
          send("#{key}=", value)
        elsif instance_variable_defined?("@#{key}")
          instance_variable_set("@#{key}", value)
        end
      end
      
      # Update the attributes hash
      @attributes.merge!(normalized)
    end

    # ListObject for handling paginated results
    class ListObject
      include Enumerable

      attr_reader :data, :has_next_page, :next_page_cursor, :total_count

      def initialize(response, resource_class, params, opts)
        @resource_class = resource_class
        @params = params
        @opts = opts
        
        @data = (response[:data] || []).map { |item| resource_class.new(item, opts) }
        
        pagination = response[:pagination] || {}
        @has_next_page = pagination[:has_next_page] || false
        @next_page_cursor = pagination[:next_page_cursor]
        @total_count = pagination[:total_count]
      end

      def each(&block)
        return enum_for(:each) unless block_given?
        @data.each(&block)
      end

      def auto_paging_each(&block)
        return enum_for(:auto_paging_each) unless block_given?
        
        page = self
        loop do
          page.each(&block)
          break unless page.has_next_page
          page = page.next_page
        end
      end

      def next_page
        return nil unless has_next_page
        
        params = @params.merge(cursor: next_page_cursor)
        @resource_class.list(params, **@opts)
      end

      def empty?
        @data.empty?
      end

      def first
        @data.first
      end

      def last
        @data.last
      end

      def size
        @data.size
      end
      alias_method :count, :size
      alias_method :length, :size

      def to_a
        @data
      end

      def inspect
        "#<#{self.class.name} data=#{@data.size} has_next=#{@has_next_page}>"
      end
    end
  end
end