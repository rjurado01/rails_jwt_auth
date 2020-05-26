RailsJwtAuth.setup do |config|
  # authentication model class name
  config.model_name = 'ActiveRecordUser'

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

  # url used to create email link with confirmation token
  #config.confirm_email_url = 'http://frontend.com/confirmation'

  # expiration time for confirmation tokens
  #config.confirmation_expiration_time = 1.day

  # url used to create email link with reset password token
  #config.reset_password_url = 'http://frontend.com/reset_password'

  # expiration time for reset password tokens
  #config.reset_password_expiration_time = 1.day

  # uses deliver_later to send emails instead of deliver method
  #config.deliver_later = false

  # time an invitation is valid after sent
  # config.invitation_expiration_time = 2.days

  # url used to create email link with activation token parameter to accept invitation
  #config.accept_invitation_url = 'http://frontend.com/accept_invitation'

  # maximum login attempts before locking an account
  #config.maximum_attempts = 3

  # strategy to lock an account: :none or :failed_attempts
  #config.lock_strategy = :failed_attempts

  # strategy to use when unlocking accounts: :time, :email or :both
  #config.unlock_strategy = :time

  # interval to unlock an account if unlock_strategy is :time
  #config.unlock_in = 60.minutes

  # interval after which to reset failed attempts counter of an account
  #config.reset_attempts_in = 60.minutes

  # url used to create email link with unlock token
  #config.unlock_account_url = 'http://frontend.com/unlock-account'
end
