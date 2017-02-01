Rails.application.routes.draw do
  resource :session, controller: 'rails_token_auth/sessions', only: [:create, :destroy]
  resource :registration, controller: 'rails_token_auth/registrations', only: [:create, :update, :destroy]
end
