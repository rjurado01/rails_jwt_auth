require 'bcrypt'

require 'rails_jwt_auth/engine'
require 'rails_jwt_auth/jwt_manager'

module RailsJwtAuth
  InvalidEmailField = Class.new(StandardError)
  InvalidAuthField = Class.new(StandardError)
  NotConfirmationsUrl = Class.new(StandardError)
  NotInvitationsUrl = Class.new(StandardError)
  NotResetPasswordsUrl = Class.new(StandardError)
  NotSetPasswordsUrl = Class.new(StandardError)

  mattr_accessor :model_name
  self.model_name = 'User'

  mattr_accessor :auth_field_name
  self.auth_field_name = 'email'

  mattr_accessor :email_field_name
  self.email_field_name = 'email'

  mattr_accessor :jwt_expiration_time
  self.jwt_expiration_time = 7.days

  mattr_accessor :jwt_issuer
  self.jwt_issuer = 'RailsJwtAuth'

  mattr_accessor :simultaneous_sessions
  self.simultaneous_sessions = 2

  mattr_accessor :mailer_sender
  self.mailer_sender = 'initialize-mailer_sender@example.com'

  mattr_accessor :confirmation_expiration_time
  self.confirmation_expiration_time = 1.day

  mattr_accessor :reset_password_expiration_time
  self.reset_password_expiration_time = 1.day

  mattr_accessor :invitation_expiration_time
  self.invitation_expiration_time = 2.days

  mattr_accessor :confirmations_url
  self.confirmations_url = nil

  mattr_accessor :reset_passwords_url
  self.reset_passwords_url = nil

  mattr_accessor :set_passwords_url
  self.set_passwords_url = nil

  mattr_accessor :invitations_url
  self.invitations_url = nil

  mattr_accessor :deliver_later
  self.deliver_later = false

  def self.model
    model_name.constantize
  end

  def self.table_name
    model_name.underscore.pluralize
  end

  def self.setup
    yield self
  end

  def self.auth_field_name!
    field_name = RailsJwtAuth.auth_field_name
    klass = RailsJwtAuth.model

    unless field_name.present? &&
           (klass.respond_to?(:column_names) && klass.column_names.include?(field_name) ||
            klass.respond_to?(:fields) && klass.fields[field_name])
      raise RailsJwtAuth::InvalidAuthField
    end

    field_name
  end

  def self.email_field_name!
    field_name = RailsJwtAuth.email_field_name
    klass = RailsJwtAuth.model

    unless field_name.present? &&
           (klass.respond_to?(:column_names) && klass.column_names.include?(field_name) ||
            klass.respond_to?(:fields) && klass.fields[field_name])
      raise RailsJwtAuth::InvalidEmailField
    end

    field_name
  end
end
