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
        end
      end
    end

    module ClassMethods
      # Creates an user and sends an invitation to him.
      def invite!(attributes={})
        attrs = ActiveSupport::HashWithIndifferentAccess.new(attributes.to_h)
        auth_field = RailsJwtAuth.auth_field_name
        auth_attribute = attrs.delete(auth_field)

        record = RailsJwtAuth.model.find_or_initialize_by(auth_field => auth_attribute)
        record.assign_attributes(attrs)

        record.invite!
        record
      end
    end

    # Sends an invitation to user
    # If the user has pending invitation, new one is sent
    def invite!
      RailsJwtAuth.email_field_name # ensure email field is valid

      if persisted? && !invitation_token
        errors.add(RailsJwtAuth.auth_field_name, :registered)
        return false
      end

      @inviting = true
      self.invitation_token = RailsJwtAuth.friendly_token
      self.invitation_sent_at = Time.current

      return false unless save_without_password

      RailsJwtAuth.send_email(RailsJwtAuth.mailer.send_invitation(self))
    ensure
      @inviting = false
    end

    # Finishes invitation process setting user password
    def accept_invitation!(params)
      return false unless invitation_token.present?

      self.assign_attributes(params)

      valid?
      errors.add(:password, :blank) if params[:password].blank?
      errors.add(:invitation_token, :expired) if expired_invitation_token?

      return false unless errors.empty?

      self.invitation_accepted_at = Time.current
      self.invitation_token = nil
      self.invitation_sent_at = nil
      self.confirmed_at = Time.current if respond_to?(:confirmed_at) && confirmed_at.nil?
      save
    end

    def inviting?
      @inviting || false
    end

    def expired_invitation_token?
      expiration_time = RailsJwtAuth.invitation_expiration_time
      return false if expiration_time.to_i.zero?

      invitation_sent_at && invitation_sent_at < expiration_time.ago
    end
  end
end
