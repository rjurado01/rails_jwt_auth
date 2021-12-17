module RailsJwtAuth
  class Engine < ::Rails::Engine
    initializer 'rails_jwt.omniauth', after: :load_config_initializers, before: :build_middleware_stack do |app|
      app.middleware.use ActionDispatch::Session::CacheStore
      RailsJwtAuth.omniauth_configs.each do |provider, config|
        app.middleware.use config.strategy_class, *config.args do |strategy|
          config.strategy = strategy
        end
      end
    end
  end
end
