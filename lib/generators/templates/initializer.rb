RailsTokenAuth.setup do |config|
  # authentication model class name
  #config.model_name = 'User'

  # field name used to authentication with password
  #config.auth_field_name = 'email'

  # set to true to validate auth_field email format
  #config.auth_field_email = true

  # expiration time for generated tokens
  #config.jwt_expiration_time = 7.days

  # The "iss" (issuer) claim identifies the principal that issued the JWT
  #config.jwt_issuer = 'RTA'
end
