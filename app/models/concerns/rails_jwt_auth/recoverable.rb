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

        validate :validate_reset_password_token, if: :password_digest_changed?

        before_update do
          self.reset_password_token = nil if password_digest_changed? && reset_password_token
        end
      end
    end

    def send_reset_password_instructions
      email_field = RailsJwtAuth.email_field_name! # ensure email field es valid

      if self.class.ancestors.include?(RailsJwtAuth::Confirmable) && !confirmed?
        errors.add(email_field, :unconfirmed)
        return false
      end

      self.reset_password_token = SecureRandom.base58(24)
      self.reset_password_sent_at = Time.current
      return false unless save

      mailer = Mailer.reset_password_instructions(self)
      RailsJwtAuth.deliver_later ? mailer.deliver_later : mailer.deliver
    end

    def set_and_send_password_instructions
      RailsJwtAuth.email_field_name! # ensure email field es valid
      return if password.present?

      self.password = SecureRandom.base58(48)
      self.password_confirmation = self.password
      self.skip_confirmation! if self.class.ancestors.include?(RailsJwtAuth::Confirmable)

      self.reset_password_token = SecureRandom.base58(24)
      self.reset_password_sent_at = Time.current
      return false unless save

      mailer = Mailer.set_password_instructions(self)
      RailsJwtAuth.deliver_later ? mailer.deliver_later : mailer.deliver
      true
    end

    protected

    def validate_reset_password_token
      if reset_password_sent_at &&
         (reset_password_sent_at < (Time.current - RailsJwtAuth.reset_password_expiration_time))
        errors.add(:reset_password_token, :expired)
      end
    end
  end
end
