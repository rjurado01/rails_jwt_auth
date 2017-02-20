module RailsJwtAuth
  module Recoverable
    def send_reset_password_instructions
      self.reset_password_token = SecureRandom.base58(24)
      self.reset_password_sent_at = Time.now

      Mailer.reset_password_instructions(self).deliver if save
    end

    def reset_password_in_progress?
      reset_password_token && reset_password_sent_at &&
        (Time.now < (reset_password_sent_at + RailsJwtAuth.reset_password_expiration_time))
    end

    def self.included(base)
      if base.ancestors.include? Mongoid::Document
        base.send(:field, :reset_password_token,   type: String)
        base.send(:field, :reset_password_sent_at, type: Time)
      end
    end
  end
end
