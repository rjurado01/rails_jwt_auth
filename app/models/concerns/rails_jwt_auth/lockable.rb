module RailsJwtAuth
  module Lockable
    BOTH_UNLOCK_STRATEGIES = %i[time email].freeze

    def self.included(base)
      base.class_eval do
        if defined?(Mongoid) && ancestors.include?(Mongoid::Document)
          field :failed_attempts,         type: Integer
          field :unlock_token,            type: String
          field :first_failed_attempt_at, type: Time
          field :locked_at,               type: Time
        end
      end
    end

    def lock_access
      self.locked_at = Time.current

      save(validate: false).tap do |result|
        send_unlock_instructions if result && unlock_strategy_enabled?(:email)
      end
    end

    def clean_lock
      self.locked_at = nil
      self.unlock_token = nil
      reset_attempts
    end

    def unlock_access
      clean_lock

      save(validate: false) if changed?
    end

    def access_locked?
      locked_at && !lock_expired?
    end

    def failed_attempt
      return if access_locked?

      reset_attempts if attempts_expired?

      self.failed_attempts ||= 0
      self.failed_attempts += 1
      self.first_failed_attempt_at = Time.current if failed_attempts == 1

      save(validate: false).tap do |result|
        lock_access if result && attempts_exceeded?
      end
    end

    protected

    def send_unlock_instructions
      self.unlock_token = SecureRandom.base58(24)
      save(validate: false)

      RailsJwtAuth.send_email(:unlock_instructions, self)
    end

    def lock_expired?
      if unlock_strategy_enabled?(:time)
        locked_at && locked_at < RailsJwtAuth.unlock_in.ago
      else
        false
      end
    end

    def reset_attempts
      self.failed_attempts = 0
      self.first_failed_attempt_at = nil
    end

    def remaining_attempts
      RailsJwtAuth.maximum_attempts - failed_attempts.to_i
    end

    def attempts_exceeded?
      !remaining_attempts.positive?
    end

    def attempts_expired?
      first_failed_attempt_at && first_failed_attempt_at < RailsJwtAuth.reset_attempts_in.ago
    end

    def lock_strategy_enabled?(strategy)
      RailsJwtAuth.lock_strategy == strategy
    end

    def unlock_strategy_enabled?(strategy)
      RailsJwtAuth.unlock_strategy == strategy ||
        (RailsJwtAuth.unlock_strategy == :both && BOTH_UNLOCK_STRATEGIES.include?(strategy))
    end
  end
end
