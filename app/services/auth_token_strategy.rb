class AuthTokenStrategy < ::Warden::Strategies::Base
  def valid?
    authentication_token
  end

  def authenticate!
    user = User.where(auth_token: authentication_token).first
    user.nil? ? fail!('strategies.authentication_token.failed') : success!(user)
  end

  private

  def authentication_token
    params['auth_token']
  end
end
