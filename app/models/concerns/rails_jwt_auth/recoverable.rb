module RailsJwtAuth
  module Recoverable
    def self.included(base)
      base.class_eval do
        if defined?(Mongoid) && base.ancestors.include?(Mongoid::Document)
          # include GlobalID::Identification to use deliver_later method
          # http://edgeguides.rubyonrails.org/active_job_basics.html#globalid
          include GlobalID::Identification if RailsJwtAuth.deliver_later

          field :reset_password_token,   type: String
          field :reset_password_sent_at, type: Time
        end
      end
    end

    def send_reset_password_instructions
      email_field = RailsJwtAuth.email_field_name # ensure email field es valid

      if self.class.ancestors.include?(RailsJwtAuth::Confirmable) && !confirmed?
        errors.add(email_field, :unconfirmed)
        return false
      end

      if self.class.ancestors.include?(RailsJwtAuth::Lockable) &&
         lock_strategy_enabled?(:failed_attempts) && access_locked?
        errors.add(email_field, :locked)
        return false
      end

      self.reset_password_token = RailsJwtAuth.friendly_token
      self.reset_password_sent_at = Time.current
      return false unless save

      RailsJwtAuth.send_email(:reset_password_instructions, self)
    end

    def set_reset_password(params)
      self.assign_attributes(params)

      valid?
      errors.add(:password, :blank) if params[:password].blank?
      errors.add(:reset_password_token, :expired) if expired_reset_password_token?

      return false unless errors.empty?

      clean_reset_password
      self.auth_tokens = [] # reset all sessions
      save
    end

    def expired_reset_password_token?
      expiration_time = RailsJwtAuth.reset_password_expiration_time
      return false if expiration_time.to_i.zero?

      reset_password_sent_at && reset_password_sent_at < expiration_time.ago
    end

    def clean_reset_password
      self.reset_password_sent_at = nil
      self.reset_password_token = nil
    end
  end
end
