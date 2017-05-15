module RailsJwtAuth
  module Recoverable
    def send_reset_password_instructions
      if self.class.ancestors.include?(RailsJwtAuth::Confirmable) && !confirmed?
        errors.add(:email, I18n.t('rails_jwt_auth.errors.unconfirmed'))
        return false
      end

      self.reset_password_token = SecureRandom.base58(24)
      self.reset_password_sent_at = Time.now
      return false unless save

      mailer = Mailer.reset_password_instructions(self)
      RailsJwtAuth.deliver_later ? mailer.deliver_later : mailer.deliver
    end

    def set_and_send_password_instructions
      return if password.present?

      self.password = SecureRandom.base58(48)
      self.password_confirmation = self.password
      self.skip_confirmation! if self.class.ancestors.include?(RailsJwtAuth::Confirmable)

      self.reset_password_token = SecureRandom.base58(24)
      self.reset_password_sent_at = Time.now
      return false unless save

      mailer = Mailer.set_password_instructions(self)
      RailsJwtAuth.deliver_later ? mailer.deliver_later : mailer.deliver
      true
    end

    def self.included(base)
      if base.ancestors.include? Mongoid::Document
        # include GlobalID::Identification to use deliver_later method
        # http://edgeguides.rubyonrails.org/active_job_basics.html#globalid
        base.send(:include, GlobalID::Identification) if RailsJwtAuth.deliver_later

        base.send(:field, :reset_password_token,   type: String)
        base.send(:field, :reset_password_sent_at, type: Time)
      end

      base.send(:before_update) do
        if password_digest_changed? && reset_password_token
          self.reset_password_token = nil
        end
      end
    end
  end
end
