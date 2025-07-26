# frozen_string_literal: true

module Attio
  module APIOperations
    module List
      module ClassMethods
        def list(params = {}, opts = {})
          request = RequestBuilder.build(
            method: :GET,
            path: resource_path,
            params: params,
            headers: opts[:headers] || {},
            api_key: opts[:api_key]
          )
          
          response = connection_manager.execute(request)
          parsed = ResponseParser.parse(response, request)
          
          ListObject.new(parsed, self, params, opts)
        end
        alias all list

        def each(params = {}, opts = {}, &block)
          return enum_for(:each, params, opts) unless block_given?
          
          list(params, opts).auto_paging_each(&block)
        end

        def each_page(params = {}, opts = {}, &block)
          return enum_for(:each_page, params, opts) unless block_given?
          
          cursor = nil
          
          loop do
            page_params = params.merge(cursor ? { cursor: cursor } : {})
            page = list(page_params, opts)
            
            yield page
            
            break unless page.has_next_page?
            cursor = page.next_cursor
          end
        end

        private

        def connection_manager
          @connection_manager ||= Util::ConnectionManager.new
        end
      end

      def self.included(base)
        base.extend(ClassMethods)
      end

      class ListObject
        include Enumerable

        attr_reader :data, :pagination, :resource_class, :params, :opts

        def initialize(response, resource_class, params = {}, opts = {})
          @resource_class = resource_class
          @params = params
          @opts = opts
          
          if response.is_a?(Hash) && response.key?(:data)
            @data = (response[:data] || []).map { |item| resource_class.new(item, opts) }
            @pagination = response[:pagination] || {}
          else
            # Handle non-paginated responses
            @data = Array(response).map { |item| resource_class.new(item, opts) }
            @pagination = {}
          end
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
            
            break unless page.has_next_page?
            
            page = fetch_next_page(page)
          end
        end

        def empty?
          @data.empty?
        end

        def size
          @data.size
        end
        alias length size
        alias count size

        def first
          @data.first
        end

        def last
          @data.last
        end

        def [](index)
          @data[index]
        end

        # Pagination methods
        def has_next_page?
          @pagination[:has_next_page] == true
        end

        def has_previous_page?
          @pagination[:has_previous_page] == true
        end

        def next_cursor
          @pagination[:next_cursor]
        end

        def previous_cursor
          @pagination[:previous_cursor]
        end

        def total_count
          @pagination[:total_count]
        end

        def page_size
          @pagination[:page_size]
        end

        def to_a
          @data
        end

        def to_h
          {
            data: @data.map(&:to_h),
            pagination: @pagination
          }
        end

        def inspect
          "#<#{self.class.name}:#{object_id} data=[#{@data.size} items] pagination=#{@pagination.inspect}>"
        end

        private

        def fetch_next_page(current_page)
          next_params = @params.merge(cursor: current_page.next_cursor)
          @resource_class.list(next_params, @opts)
        end
      end
    end
  end
end