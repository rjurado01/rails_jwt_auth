# frozen_string_literal: true

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
      end
    end

    def send_confirmation_instructions
      if confirmed? && !unconfirmed_email
        errors.add(RailsJwtAuth.email_field_name, :already_confirmed)
        return false
      end

      self.confirmation_token = SecureRandom.base58(24)
      self.confirmation_sent_at = Time.current
      return false unless save

      RailsJwtAuth.send_email(:confirmation_instructions, self)
      true
    end

    def confirmed?
      confirmed_at.present?
    end

    def confirm
      self.confirmed_at = Time.current
      self.confirmation_token = nil

      if unconfirmed_email
        email_field = RailsJwtAuth.email_field_name

        self[email_field] = unconfirmed_email
        self.unconfirmed_email = nil

        # supports email confirmation attr_accessor validation
        if respond_to?("#{email_field}_confirmation")
          instance_variable_set("@#{email_field}_confirmation", self[email_field])
        end
      end

      save
    end

    def skip_confirmation
      self.confirmed_at = Time.current
      self.confirmation_token = nil
    end

    def update_email(params)
      email_field = RailsJwtAuth.email_field_name.to_sym
      params = HashWithIndifferentAccess.new(params)

      # email change must be protected by password
      password_error = if (password = params[:password]).blank?
                         :blank
                       elsif !authenticate(password)
                         :invalid
                       end

      self.email = params[email_field]
      self.confirmation_token = SecureRandom.base58(24)
      self.confirmation_sent_at = Time.current

      valid? # validates first other fields
      errors.add(:password, password_error) if password_error
      errors.add(email_field, :not_change) unless email_changed?

      return false unless errors.empty?

      # move email to unconfirmed_email field and restore
      self.unconfirmed_email = email
      self.email = email_was

      return false unless save

      deliver_email_changed_emails

      true
    end

    protected

    def validate_confirmation
      return true unless confirmed_at

      email_field = RailsJwtAuth.email_field_name

      if confirmed_at_was && !public_send("#{email_field}_changed?")
        errors.add(email_field, :already_confirmed)
      elsif confirmation_sent_at &&
            (confirmation_sent_at < (Time.current - RailsJwtAuth.confirmation_expiration_time))
        errors.add(:confirmation_token, :expired)
      end
    end

    def deliver_email_changed_emails
      # send confirmation to new email
      RailsJwtAuth.send_email(:confirmation_instructions, self)

      # send notify to old email
      if RailsJwtAuth.send_email_change_requested_notification
        RailsJwtAuth.send_email(:email_change_requested_notification, self)
      end
    end
  end
end
