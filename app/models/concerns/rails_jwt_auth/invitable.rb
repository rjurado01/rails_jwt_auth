module RailsJwtAuth
  module Invitable
    extend ActiveSupport::Concern

    def self.included(base)
      base.extend ClassMethods
      base.class_eval do
        if ancestors.include? Mongoid::Document
          # include GlobalID::Identification to use deliver_later method
          # http://edgeguides.rubyonrails.org/active_job_basics.html#globalid
          include GlobalID::Identification if RailsJwtAuth.deliver_later

          field :invitation_token,         type: String
          field :invitation_sent_at,       type: Time
          field :invitation_accepted_at,   type: Time
          field :invitation_created_at,    type: Time

          index({invitation_token: 1}, {unique: true})
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
      #
      # @return [user] The user created or found by email.

      # rubocop:disable Metrics/AbcSize
      def invite!(attributes={})
        attrs = ActiveSupport::HashWithIndifferentAccess.new(attributes.to_h)
        auth_field = RailsJwtAuth.auth_field_name
        auth_attribute = attrs.delete(auth_field)

        raise ArgumentError unless auth_attribute

        record = RailsJwtAuth.model.find_or_initialize_by(auth_field => auth_attribute)
        record.assign_attributes(attrs)
        record.invitation_created_at = Time.now.utc if record.new_record?

        unless record.password || record.password_digest
          password = SecureRandom.base58(16)
          record.password = password
          record.password_confirmation = password
        end

        record.valid?

        # Users that are registered and were not invited are not reinvitable
        if !record.new_record? && !record.invited?
          record.errors.add(RailsJwtAuth.auth_field_name, :taken)
        end

        # Users that have already accepted an invitation are not reinvitable
        if !record.new_record? && record.invited? && record.invitation_accepted_at.present?
          record.errors.add(RailsJwtAuth.auth_field_name, :taken)
        end

        record.invite! if record.errors.empty?
        record
      end
      # rubocop:enable Metrics/AbcSize
    end

    # Accept an invitation by clearing token and setting invitation_accepted_at
    def accept_invitation
      self.invitation_accepted_at = Time.now.utc
      self.invitation_token = nil
    end

    def accept_invitation!
      return unless invited?
      if valid_invitation?
        accept_invitation
        self.confirmed_at = Time.now.utc if respond_to? :confirmed_at
      else
        errors.add(:invitation_token, :invalid)
      end
    end

    def invite!
      generate_invitation_token if invitation_token.nil?
      self.invitation_sent_at = Time.now.utc

      send_invitation_mail if save(validate: false)
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

    protected

    def generate_invitation_token
      self.invitation_token = SecureRandom.base58(128)
    end

    def send_invitation_mail
      mailer = Mailer.send_invitation(self)
      RailsJwtAuth.deliver_later ? mailer.deliver_later : mailer.deliver
    end

    def invitation_period_valid?
      time = invitation_sent_at || invitation_created_at
      expiration_time = RailsJwtAuth.invitation_expiration_time
      time && (expiration_time.to_i.zero? || time.utc >= expiration_time.ago)
    end
  end
end
