module RailsJwtAuth
  module Spec
    module Helpers
      require 'rails_jwt_auth/not_authorized_error'
      require 'rails_jwt_auth/jwt_manager'

      def sign_out
        request.env['warden'] = RailsJwtAuth::JwtStrategy.new request.env
        allow(request.env['warden']).to receive(:authenticate!).and_raise(RailsJwtAuth::NotAuthorizedError)
      end

      def sign_in(user)
        request.env['warden'] = RailsJwtAuth::JwtStrategy.new request.env
        allow(request.env['warden']).to receive(:authenticate!).and_return(user)
        allow(controller).to receive(:current_user).and_return(user)

        user.auth_tokens = []
        token = user.regenerate_auth_token
        request.env['HTTP_AUTHORIZATION'] = RailsJwtAuth::JwtManager.encode(auth_token: token)
      end
    end
  end
end
