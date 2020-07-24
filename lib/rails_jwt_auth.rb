require 'bcrypt'

require 'rails_jwt_auth/engine'
require 'rails_jwt_auth/jwt_manager'
require 'rails_jwt_auth/session'

module RailsJwtAuth
  NotConfirmationsUrl = Class.new(StandardError)
  NotInvitationsUrl = Class.new(StandardError)
  NotResetPasswordsUrl = Class.new(StandardError)
  NotUnlockUrl = Class.new(StandardError)

  mattr_accessor :model_name
  self.model_name = 'User'

  mattr_accessor :auth_field_name
  self.auth_field_name = 'email'

  mattr_accessor :email_field_name
  self.email_field_name = 'email'

  mattr_accessor :email_regex
  self.email_regex = URI::MailTo::EMAIL_REGEXP

  mattr_accessor :downcase_auth_field
  self.downcase_auth_field = false

  mattr_accessor :jwt_expiration_time
  self.jwt_expiration_time = 7.days

  mattr_accessor :jwt_issuer
  self.jwt_issuer = 'RailsJwtAuth'

  mattr_accessor :simultaneous_sessions
  self.simultaneous_sessions = 2

  mattr_accessor :mailer_name
  self.mailer_name = 'RailsJwtAuth::Mailer'

  mattr_accessor :mailer_sender
  self.mailer_sender = 'initialize-mailer_sender@example.com'

  mattr_accessor :send_email_change_requested_notification
  self.send_email_change_requested_notification = true

  mattr_accessor :send_password_changed_notification
  self.send_password_changed_notification = true

  mattr_accessor :confirmation_expiration_time
  self.confirmation_expiration_time = 1.day

  mattr_accessor :reset_password_expiration_time
  self.reset_password_expiration_time = 1.day

  mattr_accessor :invitation_expiration_time
  self.invitation_expiration_time = 2.days

  mattr_accessor :deliver_later
  self.deliver_later = false

  mattr_accessor :maximum_attempts
  self.maximum_attempts = 3

  mattr_accessor :lock_strategy
  self.lock_strategy = :none

  mattr_accessor :unlock_strategy
  self.unlock_strategy = :time

  mattr_accessor :unlock_in
  self.unlock_in = 60.minutes

  mattr_accessor :reset_attempts_in
  self.reset_attempts_in = 60.minutes

  mattr_accessor :confirm_email_url
  self.confirm_email_url = nil

  mattr_accessor :reset_password_url
  self.reset_password_url = nil

  mattr_accessor :accept_invitation_url
  self.accept_invitation_url = nil

  mattr_accessor :unlock_account_url
  self.unlock_account_url = nil

  mattr_accessor :avoid_email_errors
  self.avoid_email_errors = true

  def self.setup
    yield self
  end

  def self.model
    model_name.constantize
  end

  def self.mailer
    mailer_name.constantize
  end

  def self.table_name
    model_name.underscore.pluralize
  end

  # Thanks to https://github.com/heartcombo/devise/blob/master/lib/devise.rb#L496
  def self.friendly_token(length = 24)
    # To calculate real characters, we must perform this operation.
    # See SecureRandom.urlsafe_base64
    rlength = (length * 3 / 4) - 1
    SecureRandom.urlsafe_base64(rlength, true).tr('lIO0', 'sxyz')
  end

  def self.send_email(method, user)
    mailer = RailsJwtAuth.mailer.with(user_id: user.id.to_s).public_send(method)
    RailsJwtAuth.deliver_later ? mailer.deliver_later : mailer.deliver
  end
end
