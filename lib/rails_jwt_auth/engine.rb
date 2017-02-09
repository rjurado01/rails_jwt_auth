module RailsJwtAuth
  class Engine < ::Rails::Engine
    require 'rails_jwt_auth/jwt_strategy'

    config.generators do |g|
      g.test_framework :rspec
      g.fixture_replacement :factory_girl, dir: 'spec/factories'
    end

    initializer 'rails_jwt_auth.warden' do |app|
      app.middleware.insert_after ActionDispatch::Callbacks, Warden::Manager do |manager|
        manager.default_strategies :authentication_token
        manager.failure_app = UnauthorizedController
      end

      Warden::Strategies.add(:authentication_token, JwtStrategy)
    end
  end
end
