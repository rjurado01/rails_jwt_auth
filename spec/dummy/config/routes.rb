Rails.application.routes.draw do
  resource :session, controller: 'rails_jwt_auth/sessions', only: [:create, :destroy]
  resource :registration, controller: 'rails_jwt_auth/registrations', only: [:create, :update, :destroy]
  resource :confirmation, controller: 'rails_jwt_auth/confirmations', only: [:create, :update]
  resource :password, controller: 'rails_jwt_auth/passwords', only: [:create, :update]
end
