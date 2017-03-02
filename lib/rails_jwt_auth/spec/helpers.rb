module RailsJwtAuth
  module Spec
    module Helpers
      require 'rails_jwt_auth/spec/not_authorized'
      require 'rails_jwt_auth/jwt/manager'

      def sign_out
        request.env['warden'] = RailsJwtAuth::Strategies::Jwt.new request.env
        allow(request.env['warden']).to receive(:authenticate!).and_raise(RailsJwtAuth::Spec::NotAuthorized)
      end

      def sign_in(user)
        request.env['warden'] = RailsJwtAuth::Strategies::Jwt.new request.env
        allow(request.env['warden']).to receive(:authenticate!).and_return(user)
        allow(controller).to receive(:current_user).and_return(user)

        user.auth_tokens = []
        token = user.regenerate_auth_token
        request.env['HTTP_AUTHORIZATION'] = RailsJwtAuth::Jwt::Manager.encode(auth_token: token)
      end
    end
  end
end
