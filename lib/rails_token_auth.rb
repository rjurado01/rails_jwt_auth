require "warden"
require "bcrypt"

require "rails_token_auth/engine"

module RailsTokenAuth
  mattr_accessor :model_name
  @@model_name = 'User'

  mattr_accessor :auth_field_name
  @@auth_field_name = 'email'

  mattr_accessor :auth_field_email
  @@auth_field_email = true

  mattr_accessor :jwt_expiration_time
  @@jwt_expiration_time = 7.days

  mattr_accessor :jwt_issuer
  @@jwt_issuer = 'RTA'

  mattr_accessor :simultaneous_sessions
  @@simultaneous_sessions = 2

  def self.model
    @@model_name.constantize
  end

  def self.setup
    yield self
  end
end

# create alias
RTA = RailsTokenAuth
