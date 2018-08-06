RailsJwtAuth.setup do |config|
  # authentication model class name
  #config.model_name = 'User'

  # field name used to authentication with password
  #config.auth_field_name = 'email'

  # define email field name used to send emails
  #config.email_field_name = 'email'

  # expiration time for generated tokens
  #config.jwt_expiration_time = 7.days

  # the "iss" (issuer) claim identifies the principal that issued the JWT
  #config.jwt_issuer = 'RailsJwtAuth'

  # number of simultaneously sessions for an user
  #config.simultaneous_sessions = 2

  # mailer sender
  #config.mailer_sender = 'initialize-mailer_sender@example.com'

  # expiration time for confirmation tokens
  #config.confirmation_expiration_time = 1.day

  # expiration time for reset password tokens
  #config.reset_password_expiration_time = 1.day

  # time an invitation is valid after sent
  # config.invitation_expiration_time = 2.days

  # url used to create email link with confirmation token
  #config.confirmations_url = 'http://frontend.com/confirmation'

  # url used to create email link with reset password token
  #config.reset_passwords_url = 'http://frontend.com/reset_password'

  # url used to create email link with set password token
  # by set_and_send_password_instructions method
  #config.set_passwords_url = 'http://frontend.com/set_password'

  # url used to create email link with activation token parameter to accept invitation
  #config.invitations_url = 'http://frontend.com/accept_invitation'

  # uses deliver_later to send emails instead of deliver method
  #config.deliver_later = false
end
