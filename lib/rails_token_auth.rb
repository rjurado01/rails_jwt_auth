require "warden"
require "bcrypt"

require "rails_token_auth/engine"

module RailsTokenAuth
  mattr_accessor :model_name
  @@model_name = 'User'

  mattr_accessor :jwt_expiration_time
  @@jwt_expiration_time = 7.days

  mattr_accessor :jwt_issuer
  @@jwt_issuer = 'RTA'

  def self.model
    @@model_name.constantize
  end

  def self.setup
    yield self
  end
end

# create alias
RTA = RailsTokenAuth
