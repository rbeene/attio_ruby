# frozen_string_literal: true

require "digest"
require "json"

module Attio
  module Util
    class Cache
      DEFAULT_TTL = 3600 # 1 hour
      DEFAULT_NAMESPACE = "attio"

      attr_reader :store, :namespace, :enabled

      def initialize(store: nil, namespace: DEFAULT_NAMESPACE, enabled: true)
        @store = store || create_default_store
        @namespace = namespace
        @enabled = enabled
      end

      # Get a value from cache
      def get(key)
        return nil unless enabled
        
        namespaced_key = build_key(key)
        @store.get(namespaced_key)
      rescue StandardError => e
        handle_cache_error("get", e)
        nil
      end

      # Set a value in cache
      def set(key, value, ttl: DEFAULT_TTL)
        return value unless enabled
        
        namespaced_key = build_key(key)
        @store.set(namespaced_key, value, ttl: ttl)
        value
      rescue StandardError => e
        handle_cache_error("set", e)
        value
      end

      # Delete a value from cache
      def delete(key)
        return unless enabled
        
        namespaced_key = build_key(key)
        @store.delete(namespaced_key)
      rescue StandardError => e
        handle_cache_error("delete", e)
      end

      # Clear all cached values in namespace
      def clear
        return unless enabled
        
        @store.clear(namespace: namespace)
      rescue StandardError => e
        handle_cache_error("clear", e)
      end

      # Fetch with block for cache miss
      def fetch(key, ttl: DEFAULT_TTL, &block)
        return yield if !enabled || !block_given?
        
        cached = get(key)
        return cached unless cached.nil?
        
        value = yield
        set(key, value, ttl: ttl)
        value
      end

      # Check if key exists
      def exist?(key)
        return false unless enabled
        
        namespaced_key = build_key(key)
        @store.exist?(namespaced_key)
      rescue StandardError => e
        handle_cache_error("exist?", e)
        false
      end

      # Cache API responses
      def cache_response(request, response, ttl: DEFAULT_TTL)
        return response unless enabled && cacheable_request?(request)
        
        cache_key = request_cache_key(request)
        set(cache_key, response, ttl: ttl)
        response
      end

      # Get cached API response
      def get_cached_response(request)
        return nil unless enabled && cacheable_request?(request)
        
        cache_key = request_cache_key(request)
        get(cache_key)
      end

      # Invalidate cache for a resource
      def invalidate_resource(resource_type, resource_id = nil)
        return unless enabled
        
        pattern = if resource_id
                    "#{resource_type}:#{resource_id}:*"
                  else
                    "#{resource_type}:*"
                  end
        
        delete_pattern(pattern)
      end

      # Invalidate cache for an object's records
      def invalidate_object_records(object_slug)
        invalidate_resource("records:#{object_slug}")
      end

      private

      def build_key(key)
        "#{namespace}:#{key}"
      end

      def request_cache_key(request)
        method = request[:method].to_s.upcase
        path = request[:uri].path
        params = request[:params] || {}
        
        # Only cache GET requests
        return nil unless method == "GET"
        
        # Build cache key from request details
        cache_parts = [
          "request",
          method,
          path.gsub("/", ":"),
          Digest::MD5.hexdigest(params.to_json)
        ]
        
        cache_parts.join(":")
      end

      def cacheable_request?(request)
        # Only cache GET requests
        request[:method].to_s.upcase == "GET"
      end

      def delete_pattern(pattern)
        namespaced_pattern = build_key(pattern)
        
        if @store.respond_to?(:delete_matched)
          @store.delete_matched(namespaced_pattern)
        else
          # Fallback for stores that don't support pattern deletion
          warn "Cache store doesn't support pattern deletion"
        end
      end

      def handle_cache_error(operation, error)
        # Log error but don't raise - cache errors shouldn't break the app
        if Attio.configuration.logger
          Attio.configuration.logger.warn(
            "[Attio Cache] Error during #{operation}: #{error.class} - #{error.message}"
          )
        end
      end

      def create_default_store
        # Use in-memory store by default
        MemoryStore.new
      end

      # Simple in-memory cache store
      class MemoryStore
        def initialize
          @data = {}
          @expires = {}
          @mutex = Mutex.new
        end

        def get(key)
          @mutex.synchronize do
            cleanup_expired
            return nil unless @data.key?(key)
            return nil if expired?(key)
            
            @data[key]
          end
        end

        def set(key, value, ttl: DEFAULT_TTL)
          @mutex.synchronize do
            @data[key] = value
            @expires[key] = Time.now + ttl if ttl && ttl > 0
            cleanup_expired if @data.size > 1000 # Basic size limit
            value
          end
        end

        def delete(key)
          @mutex.synchronize do
            @data.delete(key)
            @expires.delete(key)
          end
        end

        def exist?(key)
          @mutex.synchronize do
            @data.key?(key) && !expired?(key)
          end
        end

        def clear(namespace: nil)
          @mutex.synchronize do
            if namespace
              pattern = "^#{Regexp.escape(namespace)}:"
              @data.keys.grep(/#{pattern}/).each do |key|
                @data.delete(key)
                @expires.delete(key)
              end
            else
              @data.clear
              @expires.clear
            end
          end
        end

        def delete_matched(pattern)
          @mutex.synchronize do
            regex = pattern.gsub("*", ".*")
            @data.keys.grep(/^#{regex}$/).each do |key|
              @data.delete(key)
              @expires.delete(key)
            end
          end
        end

        private

        def expired?(key)
          @expires[key] && @expires[key] < Time.now
        end

        def cleanup_expired
          now = Time.now
          @expires.each do |key, expiry|
            if expiry < now
              @data.delete(key)
              @expires.delete(key)
            end
          end
        end
      end

      # Redis store adapter
      class RedisStore
        def initialize(redis_client)
          @redis = redis_client
        end

        def get(key)
          value = @redis.get(key)
          value ? JSON.parse(value, symbolize_names: true) : nil
        rescue JSON::ParserError
          value
        end

        def set(key, value, ttl: DEFAULT_TTL)
          json_value = value.is_a?(String) ? value : JSON.generate(value)
          
          if ttl && ttl > 0
            @redis.setex(key, ttl, json_value)
          else
            @redis.set(key, json_value)
          end
          
          value
        end

        def delete(key)
          @redis.del(key)
        end

        def exist?(key)
          @redis.exists?(key)
        end

        def clear(namespace: nil)
          if namespace
            keys = @redis.keys("#{namespace}:*")
            @redis.del(*keys) unless keys.empty?
          else
            @redis.flushdb
          end
        end

        def delete_matched(pattern)
          keys = @redis.keys(pattern)
          @redis.del(*keys) unless keys.empty?
        end
      end
    end
  end
end