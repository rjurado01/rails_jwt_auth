module RailsJwtAuth
  module Invitable
    extend ActiveSupport::Concern

    attr_accessor :skip_invitation

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

          index({ invitation_token: 1 }, { unique: true })
        end
      end
    end

    module ClassMethods
      def invite!(attributes={}, &block)
        attr_hash = ActiveSupport::HashWithIndifferentAccess.new(attributes.to_h)
        _invite(attr_hash, &block).first
      end

      def invite_mail!(attributes={}, &block)
        _invite(attributes, &block).last
      end

      # Creates an user and sends invitation to him,
      # if the user already exists and it's confirmed, it returns the record with taken auth_field_name error.
      # If the user exists and is already invited, resends the invitation.
      def _invite(attributes={}, &block)
        auth_field = RailsJwtAuth.auth_field_name
        auth_attribute = attributes.delete(auth_field)
        unless auth_attribute
          raise ArgumentError
        end

        record = RailsJwtAuth.model.find_or_initialize_by(auth_field => auth_attribute)
        record.assign_attributes(attributes)
        record.invitation_created_at = Time.now.utc if record.new_record?

        unless record.password || record.password_digest
          password = SecureRandom.base58(16)
          record.password  = password
          record.password_confirmation = password
        end

        record.valid?

        if !record.new_record? && !record.invited?
          record.errors.add(RailsJwtAuth.auth_field_name, :taken)
        end

        yield record if block_given?

        mail = record.invite! if record.errors.empty?
        [record, mail]
      end
    end

    # Accept an invitation by clearing token and setting invitation_accepted_at
    def accept_invitation
      self.invitation_accepted_at = Time.now.utc
      self.invitation_token = nil
    end

    def accept_invitation!
      if self.invited?
        if self.valid_invitation?
          self.accept_invitation
          # Override confirmable
          self.confirmed_at = self.invitation_accepted_at if self.respond_to? :confirmed_at
        else
          self.errors.add(:invitation_token, :invalid)
        end
      end
    end

    def invite!
      yield self if block_given?

      generate_invitation_token if self.invitation_token.nil?

      self.invitation_created_at = Time.now.utc
      self.invitation_sent_at = invitation_created_at unless skip_invitation

      if save(:validate => false)
        deliver_invitation unless skip_invitation
      end
    end

    def invited?
      (persisted? && invitation_token.present?)
    end

    protected

    def deliver_invitation
      mailer = Mailer.send_invitation(self)
      RailsJwtAuth.deliver_later ? mailer.deliver_later : mailer.deliver
    end

    def generate_invitation_token
      self.invitation_token = SecureRandom.base58(128)
    end

    def valid_invitation?
      invited? && invitation_period_valid?
    end

    def invitation_period_valid?
      time = invitation_sent_at || invitation_created_at
      expiration_time = RailsJwtAuth.invitation_expiration_time
      time && (expiration_time.to_i.zero? || time.utc >= expiration_time.ago)
    end
  end
end
