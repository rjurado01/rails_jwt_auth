module RailsJwtAuth
  module Spec
    module Helpers
      require 'rails_jwt_auth/jwt_manager'

      def sign_in(user)
        allow(controller).to receive(:authenticate!).and_returns(true)
        allow(controller).to receive(:current_user).and_returns(user)
      end

      def get_jwt(user)
        payload = user.to_token_payload request
        RailsJwtAuth::JwtManager.encode(payload)
      end
    end
  end
end
