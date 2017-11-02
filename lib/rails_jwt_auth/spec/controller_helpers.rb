module RailsJwtAuth
  module Spec
    module ControllerHelpers
      require 'rails_jwt_auth/spec/not_authorized'

      def sign_out
        allow(controller).to receive(:authenticate!).and_raise(RailsJwtAuth::Spec::NotAuthorized)
      end

      def sign_in(user)
        allow(controller).to receive(:authenticate!).and_call_original

        manager = Warden::Manager.new(nil, &Rails.application.config.middleware.detect{|m| m.name == 'Warden::Manager'}.block)
        request.env['warden'] = Warden::Proxy.new(request.env, manager)
        request.env['warden'].set_user(user, store: false)
      end

      def self.included(config)
        config.before(:each) do
          sign_out
        end
      end
    end
  end
end
