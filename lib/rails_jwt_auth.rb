require "warden"
require "bcrypt"

require "rails_jwt_auth/engine"

module RailsJwtAuth
  mattr_accessor :model_name
  @@model_name = 'User'

  mattr_accessor :auth_field_name
  @@auth_field_name = 'email'

  mattr_accessor :auth_field_email
  @@auth_field_email = true

  mattr_accessor :jwt_expiration_time
  @@jwt_expiration_time = 7.days

  mattr_accessor :jwt_issuer
  @@jwt_issuer = 'RailsJwtAuth'

  mattr_accessor :simultaneous_sessions
  @@simultaneous_sessions = 2

  mattr_accessor :mailer_sender
  @@mailer_sender = "initialize-mailer_sender@example.com"

  mattr_accessor :confirmation_url
  @@confirmation_url = nil

  mattr_accessor :confirmation_expiration_time
  @@confirmation_expiration_time = 1.day

  def self.model
    @@model_name.constantize
  end

  def self.setup
    yield self
  end
end
