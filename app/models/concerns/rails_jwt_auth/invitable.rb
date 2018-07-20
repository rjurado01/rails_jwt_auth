module RailsJwtAuth
  module Invitable
    def self.included(base)
      base.extend ClassMethods
      base.class_eval do
        if defined?(Mongoid) && ancestors.include?(Mongoid::Document)
          # include GlobalID::Identification to use deliver_later method
          # http://edgeguides.rubyonrails.org/active_job_basics.html#globalid
          include GlobalID::Identification if RailsJwtAuth.deliver_later

          field :invitation_token,         type: String
          field :invitation_sent_at,       type: Time
          field :invitation_accepted_at,   type: Time
          field :invitation_created_at,    type: Time
        end
      end
    end

    module ClassMethods
      # Creates an user and sends an invitation to him.
      # If the user is already invited and pending of completing registration
      # the invitation is resent by email.
      # If the user is already registered, it returns the user with a
      # <tt>:taken</tt> on the email field.
      #
      # @param [Hash] attributes Hash containing user's attributes to be filled.
      #               Must contain an email key.
      #
      # @return [user] The user created or found by email.
      def invite!(attributes={})
        attrs = ActiveSupport::HashWithIndifferentAccess.new(attributes.to_h)
        auth_field = RailsJwtAuth.auth_field_name!
        auth_attribute = attrs.delete(auth_field)

        raise ArgumentError unless auth_attribute

        record = RailsJwtAuth.model.find_or_initialize_by(auth_field => auth_attribute)
        record.assign_attributes(attrs)

        record.invite!
        record
      end
    end

    # Accept an invitation by clearing token and setting invitation_accepted_at
    def accept_invitation
      self.invitation_accepted_at = Time.current
      self.invitation_token = nil
    end

    def accept_invitation!
      return unless invited?

      if valid_invitation?
        accept_invitation
        self.confirmed_at = Time.current if respond_to?(:confirmed_at) && confirmed_at.nil?
      else
        errors.add(:invitation_token, :invalid)
      end
    end

    def invite!
      self.invitation_created_at = Time.current if new_record?

      unless password || password_digest
        passw = SecureRandom.base58(16)
        self.password = passw
        self.password_confirmation = passw
      end

      valid?

      # users that are registered and were not invited are not reinvitable
      if !new_record? && !invited?
        errors.add(RailsJwtAuth.auth_field_name!, :taken)
      end

      # users that have already accepted an invitation are not reinvitable
      if !new_record? && invited? && invitation_accepted_at.present?
        errors.add(RailsJwtAuth.auth_field_name!, :taken)
      end

      return self unless errors.empty?

      generate_invitation_token if invitation_token.nil?
      self.invitation_sent_at = Time.current

      send_invitation_mail if save(validate: false)
      self
    end

    def invited?
      (persisted? && invitation_token.present?)
    end

    def generate_invitation_token!
      generate_invitation_token && save(validate: false)
    end

    def valid_invitation?
      invited? && invitation_period_valid?
    end

    def accepted_invitation?
      invitation_token.nil? && invitation_accepted_at.present?
    end

    protected

    def generate_invitation_token
      self.invitation_token = SecureRandom.base58(128)
    end

    def send_invitation_mail
      RailsJwtAuth.email_field_name! # ensure email field es valid
      mailer = Mailer.send_invitation(self)
      RailsJwtAuth.deliver_later ? mailer.deliver_later : mailer.deliver
    end

    def invitation_period_valid?
      time = invitation_sent_at || invitation_created_at
      expiration_time = RailsJwtAuth.invitation_expiration_time
      time && (expiration_time.to_i.zero? || time >= expiration_time.ago)
    end
  end
end
