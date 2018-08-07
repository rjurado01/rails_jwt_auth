class RailsJwtAuth::InstallGenerator < Rails::Generators::Base
  source_root File.expand_path('../../templates', __FILE__)

  def create_initializer_file
    copy_file 'initializer.rb', 'config/initializers/rails_jwt_auth.rb'
  end

  def create_routes
    route "resources :session, controller: 'rails_jwt_auth/sessions', only: [:create, :destroy]"
    route "resources :registration, controller: 'rails_jwt_auth/registrations', only: [:create, :update, :destroy]"

    route "resources :confirmations, controller: 'rails_jwt_auth/confirmations', only: [:create, :update]"
    route "resources :passwords, controller: 'rails_jwt_auth/passwords', only: [:create, :update]"
    route "resources :invitations, controller: 'rails_jwt_auth/invitations', only: [:create, :update]"
  end
end
