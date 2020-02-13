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
      email_field = RailsJwtAuth.email_field_name! # ensure email field es valid

      if self.class.ancestors.include?(RailsJwtAuth::Confirmable) && !confirmed?
        errors.add(email_field, :unconfirmed)
        return false
      end

      if self.class.ancestors.include?(RailsJwtAuth::Lockable) &&
         lock_strategy_enabled?(:failed_attempts) && access_locked?
        errors.add(email_field, :locked)
        return false
      end

      self.reset_password_token = SecureRandom.base58(24)
      self.reset_password_sent_at = Time.current
      return false unless save

      mailer = Mailer.reset_password_instructions(self)
      RailsJwtAuth.deliver_later ? mailer.deliver_later : mailer.deliver
    end

    def set_reset_password(params)
      self.assign_attributes(params)
      self.reset_password_token = nil
      self.auth_tokens = []

      valid?
      errors.add(:password, :blank) if params[:password].blank?
      errors.add(:reset_password_token, :expired) if expired_reset_password_token?

      errors.empty? ? save : false
    end

    def expired_reset_password_token?
      reset_password_sent_at &&
        (reset_password_sent_at < (Time.current - RailsJwtAuth.reset_password_expiration_time))
    end
  end
end
