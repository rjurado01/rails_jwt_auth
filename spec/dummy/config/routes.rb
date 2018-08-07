Rails.application.routes.draw do
  resource :session, controller: 'rails_jwt_auth/sessions', only: %i[create destroy]
  resource :registration, controller: 'rails_jwt_auth/registrations', only: %i[create]

  resources :confirmations, controller: 'rails_jwt_auth/confirmations', only: [:create, :update]
  resources :passwords, controller: 'rails_jwt_auth/passwords', only: [:create, :update]
  resources :invitations, controller: 'rails_jwt_auth/invitations', only: [:create, :update]
end
