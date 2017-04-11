module RailsJwtAuth
  class Engine < ::Rails::Engine
    require 'rails_jwt_auth/strategies/jwt'

    config.generators do |g|
      g.test_framework :rspec
      g.fixture_replacement :factory_girl, dir: 'spec/factories'
    end

    initializer 'rails_jwt_auth.warden' do |app|
      app.middleware.insert_after ActionDispatch::Callbacks, Warden::Manager do |manager|
        manager.default_strategies :authentication_token
        manager.failure_app = UnauthorizedController
      end

      Warden::Strategies.add(:authentication_token, Strategies::Jwt)

      Warden::Manager.after_set_user except: :fetch do |record, warden, options|
        if record.respond_to?(:update_tracked_fields!) && warden.authenticated?(options[:scope])
          record.update_tracked_fields!(warden.request)
        end
      end
    end
  end
end
