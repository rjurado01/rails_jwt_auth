module Helpers
  require 'rails_jwt_auth/not_authorized_error'

  def add_authorization(user)
    user.auth_tokens = []
    token = user.regenerate_auth_token
    request.env['HTTP_AUTHORIZATION'] = RailsJwtAuth::JwtManager.encode(auth_token: token)
  end

  def test_warden(user = nil)
    request.env['warden'] = RailsJwtAuth::JwtStrategy.new request.env
    allow(request.env['warden']).to receive('fail!').and_raise(RailsJwtAuth::NotAuthorizedError)
    add_authorization(user) if user
  end

  def sign_out
    request.env['warden'] = RailsJwtAuth::JwtStrategy.new request.env
    allow(request.env['warden']).to receive(:authenticate!).and_raise(RailsJwtAuth::NotAuthorizedError)
  end

  def sign_in(user)
    request.env['warden'] = RailsJwtAuth::JwtStrategy.new request.env
    allow(request.env['warden']).to receive(:authenticate!).and_return(user)
    allow(controller).to receive(:current_user).and_return(user)
    add_authorization(user)
  end
end
