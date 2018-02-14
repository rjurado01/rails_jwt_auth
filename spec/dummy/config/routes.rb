Rails.application.routes.draw do
  resource :registration, controller: 'rails_jwt_auth/registrations', only: [:create, :update, :destroy]
  resource :confirmation, controller: 'rails_jwt_auth/confirmations', only: [:create, :update]
  resource :password, controller: 'rails_jwt_auth/passwords', only: [:create, :update]

  resources :tokens, controller: 'rails_jwt_auth/tokens', only: [:create]
  resources :invitations, controller: 'rails_jwt_auth/invitations', only: [:create, :update]
end
