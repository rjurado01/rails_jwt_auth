module RailsJwtAuth
  module Confirmable
    def send_confirmation_instructions
      if confirmed? && !unconfirmed_email
        errors.add(:email, :already_confirmed)
        return false
      end

      self.confirmation_token = SecureRandom.base58(24)
      self.confirmation_sent_at = Time.current
      return false unless save

      mailer = Mailer.confirmation_instructions(self)
      RailsJwtAuth.deliver_later ? mailer.deliver_later : mailer.deliver
      true
    end

    def confirmed?
      confirmed_at.present?
    end

    def confirm!
      self.confirmed_at = Time.current
      self.confirmation_token = nil

      if unconfirmed_email
        self.email = unconfirmed_email
        self.email_confirmation = unconfirmed_email if respond_to?(:email_confirmation)
        self.unconfirmed_email = nil
      end

      save
    end

    def skip_confirmation!
      self.confirmed_at = Time.current
      self.confirmation_token = nil
    end

    def self.included(base)
      base.class_eval do
        if defined?(Mongoid) && ancestors.include?(Mongoid::Document)
          # include GlobalID::Identification to use deliver_later method
          # http://edgeguides.rubyonrails.org/active_job_basics.html#globalid
          include GlobalID::Identification if RailsJwtAuth.deliver_later

          field :email,                type: String
          field :unconfirmed_email,    type: String
          field :confirmation_token,   type: String
          field :confirmation_sent_at, type: Time
          field :confirmed_at,         type: Time
        end

        validate :validate_confirmation, if: :confirmed_at_changed?

        after_create do
          unless confirmed_at || confirmation_sent_at || self['invitation_token']
            send_confirmation_instructions
          end
        end

        before_update do
          if email_changed? && email_was && !confirmed_at_changed? && !self['invitation_token']
            self.unconfirmed_email = email
            self.email = email_was

            self.confirmation_token = SecureRandom.base58(24)
            self.confirmation_sent_at = Time.current

            mailer = Mailer.confirmation_instructions(self)
            RailsJwtAuth.deliver_later ? mailer.deliver_later : mailer.deliver
          end
        end
      end
    end

    private

    def validate_confirmation
      return true unless confirmed_at

      if confirmed_at_was && !email_changed?
        errors.add(:email, :already_confirmed)
      elsif confirmation_sent_at &&
            (confirmation_sent_at < (Time.current - RailsJwtAuth.confirmation_expiration_time))
        errors.add(:confirmation_token, :expired)
      end
    end
  end
end
