# frozen_string_literal: true

module Attio
  module Util
    # Handles rate limiting with exponential backoff
    # @api private
    class RateLimitHandler
      # Default wait time in seconds when no retry-after header is provided
      DEFAULT_WAIT_TIME = 60
      # Maximum wait time in seconds
      MAX_WAIT_TIME = 300
      # Jitter factor (0.1 = 10% jitter)
      JITTER_FACTOR = 0.1

      class << self
        # Handle rate limit error with automatic retry
        # @param error [RateLimitError] The rate limit error
        # @param attempt [Integer] Current attempt number
        # @return [Integer] Time to wait in seconds
        def calculate_wait_time(error, attempt = 1)
          base_wait = if error.retry_after
            [error.retry_after, MAX_WAIT_TIME].min
          else
            [DEFAULT_WAIT_TIME * (2**(attempt - 1)), MAX_WAIT_TIME].min
          end

          # Add jitter to prevent thundering herd
          add_jitter(base_wait)
        end

        # Execute a block with rate limit retry logic
        # @param max_attempts [Integer] Maximum number of attempts
        # @param logger [Logger] Optional logger
        # @yield The block to execute
        # @return The result of the block
        def with_retry(max_attempts: 3, logger: nil)
          attempt = 0

          begin
            attempt += 1
            yield
          rescue RateLimitError => e
            if attempt >= max_attempts
              log_rate_limit(logger, e, attempt, "Max attempts reached")
              raise
            end

            wait_time = calculate_wait_time(e, attempt)
            log_rate_limit(logger, e, attempt, "Waiting #{wait_time}s")

            sleep(wait_time)
            retry
          end
        end

        private

        def add_jitter(base_time)
          jitter = base_time * JITTER_FACTOR
          base_time + (rand * jitter * 2) - jitter
        end

        def log_rate_limit(logger, error, attempt, message)
          return unless logger

          logger.warn("[Attio] Rate limit hit (attempt #{attempt}): #{message}")
          logger.debug("[Attio] Rate limit details: #{error.message}")
        end
      end
    end
  end
end
