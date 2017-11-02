require 'rails_jwt_auth/jwt/request'

module RailsJwtAuth
  module Strategies
    class Jwt < ::Warden::Strategies::Base
      def authenticate!
        jwt = RailsJwtAuth::Jwt::Request.new(request)

        if jwt.valid? && (model = RailsJwtAuth.model.get_by_session_id(jwt.session_id))
          return success!(model)
        end

        fail!('strategies.authentication_token.failed')
      end
    end
  end
end
