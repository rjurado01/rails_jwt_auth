class AuthTokenStrategy < ::Warden::Strategies::Base
  def valid?
    get_payload
  end

  def authenticate!
    if !payload = get_payload || !JsonWebToken.valid_payload?(payload.first)
      fail!('strategies.authentication_token.failed')
    end

    if user = User.where(auth_token: payload[0]['auth_token']).first
      success!(user)
    else
      fail!('strategies.authentication_token.failed')
    end
  end

  private

  # Deconstructs the Authorization header and decodes the JWT token.
  def get_payload
    return nil unless auth_header = request.env['HTTP_AUTHORIZATION']
    token = auth_header.split(' ').last
    JsonWebToken.decode(token)
  rescue
    nil
  end
end
