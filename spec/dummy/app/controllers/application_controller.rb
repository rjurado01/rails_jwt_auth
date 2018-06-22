class ApplicationController < ActionController::Base
  include RailsJwtAuth::WardenHelper

  protect_from_forgery with: :exception
end
