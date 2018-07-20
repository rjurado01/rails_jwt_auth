module RailsJwtAuth
  module Confirmable
    def self.included(base)
      base.class_eval do
        if defined?(Mongoid) && ancestors.include?(Mongoid::Document)
          # include GlobalID::Identification to use deliver_later method
          # http://edgeguides.rubyonrails.org/active_job_basics.html#globalid
          include GlobalID::Identification if RailsJwtAuth.deliver_later

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
          email_field = RailsJwtAuth.email_field_name!

          if public_send("#{email_field}_changed?") &&
             public_send("#{email_field}_was") &&
             !confirmed_at_changed? &&
             !self['invitation_token']
            self.unconfirmed_email = self[email_field]
            self[email_field] = public_send("#{email_field}_was")

            self.confirmation_token = SecureRandom.base58(24)
            self.confirmation_sent_at = Time.current

            mailer = Mailer.confirmation_instructions(self)
            RailsJwtAuth.deliver_later ? mailer.deliver_later : mailer.deliver
          end
        end
      end
    end

    def send_confirmation_instructions
      email_field = RailsJwtAuth.email_field_name!

      if confirmed? && !unconfirmed_email
        errors.add(email_field, :already_confirmed)
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
        self[RailsJwtAuth.email_field_name!] = unconfirmed_email
        self.email_confirmation = unconfirmed_email if respond_to?(:email_confirmation)
        self.unconfirmed_email = nil
      end

      save
    end

    def skip_confirmation!
      self.confirmed_at = Time.current
      self.confirmation_token = nil
    end

    protected

    def validate_confirmation
      return true unless confirmed_at
      email_field = RailsJwtAuth.email_field_name!

      if confirmed_at_was && !public_send("#{email_field}_changed?")
        errors.add(email_field, :already_confirmed)
      elsif confirmation_sent_at &&
            (confirmation_sent_at < (Time.current - RailsJwtAuth.confirmation_expiration_time))
        errors.add(:confirmation_token, :expired)
      end
    end
  end
end
