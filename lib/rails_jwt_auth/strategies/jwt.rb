require 'rails_jwt_auth/jwt/request'

module RailsJwtAuth
  module Strategies
    class Jwt < ::Warden::Strategies::Base
      def authenticate!
        jwt = RailsJwtAuth::Jwt::Request.new(request)

        if jwt.valid? && (model = RailsJwtAuth.model.get_by_session_id(jwt.session_id))
          return success!(model) if valid_session?(request, model, jwt.session_id)
        end

        fail!('strategies.authentication_token.failed')
      end

      def valid_session?(request, model, session_id)
        session = model.sessions.detect { |x| x[:id] == session_id }

        (!RailsJwtAuth.validate_user_agent || request.user_agent == session[:user_agent]) &&
          (!RailsJwtAuth.validate_ip || request.ip == session[:ip])
      end
    end
  end
end
