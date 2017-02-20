class RailsJwtAuth::InstallGenerator < Rails::Generators::Base
  source_root File.expand_path('../../templates', __FILE__)

  def create_initializer_file
    copy_file "initializer.rb", "config/initializers/rails_jwt_auth.rb"
  end

  def create_routes
    route "resource :session, controller: 'rails_jwt_auth/sessions', only: [:create, :destroy]"
    route "resource :registration, controller: 'rails_jwt_auth/registrations', only: [:create, :update, :destroy]"

    route "resource :confirmation, controller: 'rails_jwt_auth/confirmations', only: [:show, :create]"
    route "resource :password, controller: 'rails_jwt_auth/passwords', only: [:create, :update]"
  end
end
