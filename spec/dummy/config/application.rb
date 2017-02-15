require_relative 'boot'

# Pick the frameworks you want:
require 'active_record/railtie'
require 'action_controller/railtie'
require 'action_view/railtie'
require 'action_mailer/railtie'
require 'active_job/railtie'
require 'action_cable/engine'
# require 'rails/test_unit/railtie'
require 'sprockets/railtie'

Bundler.require(*Rails.groups)
require 'rails_jwt_auth'

module Dummy
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    config.action_mailer.default_url_options = {host: 'http://localhost:3000'}
    config.action_mailer.delivery_method = :smtp
    config.action_mailer.smtp_settings = {address: '127.0.0.1', port: 1025}
    config.action_mailer.raise_delivery_errors = false
  end
end

