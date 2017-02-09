require 'rails_jwt_auth/jwt_request'

module RailsJwtAuth
  class JwtStrategy < ::Warden::Strategies::Base
    def authenticate!
      jwt = JwtRequest.new(request)

      if jwt.valid? && (model = RailsJwtAuth.model.get_by_token(jwt.auth_token))
        success!(model)
      else
        fail!('strategies.authentication_token.failed')
      end
    end
  end
end
