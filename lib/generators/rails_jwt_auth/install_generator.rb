class RailsJwtAuth::InstallGenerator < Rails::Generators::Base
  source_root File.expand_path('../../templates', __FILE__)

  def create_initializer_file
    copy_file 'initializer.rb', 'config/initializers/rails_jwt_auth.rb'
  end

  def create_routes
    route "resource :session, controller: 'rails_jwt_auth/sessions', only: [:create, :destroy]"
    route "resource :registration, controller: 'rails_jwt_auth/registrations', only: [:create]"
    route %q(
      resource :profile, controller: 'rails_jwt_auth/profiles', only: %i[show update] do
        collection do
          put :email
          put :password
        end
      end
    )

    route "resources :confirmations, controller: 'rails_jwt_auth/confirmations', only: [:create, :update]"
    route "resources :reset_passwords, controller: 'rails_jwt_auth/reset_passwords', only: [:show, :create, :update]"
    route "resources :invitations, controller: 'rails_jwt_auth/invitations', only: [:show, :create, :update]"
    route "resources :unlock_accounts, controller: 'rails_jwt_auth/unlock_accounts', only: %i[update]"
  end
end
