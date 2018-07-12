class ApplicationController < ActionController::Base
  include RailsJwtAuth::AuthenticableHelper

  protect_from_forgery with: :exception
end
