module RailsJwtAuth
  class JwtStrategy < ::Warden::Strategies::Base
    def valid?
      get_payload
    end

    def authenticate!
      if !payload = get_payload || !RailsJwtAuth::JsonWebToken.valid_payload?(payload.first)
        fail!('strategies.authentication_token.failed')
      end

      if model = RailsJwtAuth.model.get_by_token(payload[0]['auth_token'])
        success!(model)
      else
        fail!('strategies.authentication_token.failed')
      end
    end

    private

    # Deconstructs the Authorization header and decodes the JWT token.
    def get_payload
      return nil unless auth_header = request.env['HTTP_AUTHORIZATION']
      token = auth_header.split(' ').last
      RailsJwtAuth::JsonWebToken.decode(token)
    rescue
      nil
    end
  end
end
