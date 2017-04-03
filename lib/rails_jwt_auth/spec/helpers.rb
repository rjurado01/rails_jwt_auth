module RailsJwtAuth
  module Spec
    module Helpers
      require 'rails_jwt_auth/spec/not_authorized'

      def sign_out
        allow(controller).to receive(:authenticate!).and_raise(RailsJwtAuth::Spec::NotAuthorized)
      end

      def sign_in(user)
        manager = Warden::Manager.new(nil, &Rails.application.config.middleware.detect{|m| m.name == 'Warden::Manager'}.block)
        request.env['warden'] = Warden::Proxy.new(request.env, manager)
        request.env['warden'].set_user(user, store: false)
      end
    end
  end
end
