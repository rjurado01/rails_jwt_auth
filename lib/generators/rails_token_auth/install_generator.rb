class RailsTokenAuth::InstallGenerator < Rails::Generators::Base
  source_root File.expand_path('../../templates', __FILE__)

  def create_initializer_file
    copy_file "initializer.rb", "config/initializers/rails_token_auth.rb"
  end

  def create_routes
    route "resource :session, controller: 'rails_token_auth/sessions', only: [:create, :destroy]"
    route "resource :registration, controller: 'rails_token_auth/registrations', only: [:create, :update, :destroy]"
  end
end
