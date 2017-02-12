class ApplicationController < ActionController::Base
  include RailsJwtAuth::WardenHelper

  protect_from_forgery with: :exception

  rescue_from RailsJwtAuth::Errors::NotAuthorized, with: :render_401

  rescue_from ActionController::ParameterMissing do |exception|
    render json: {exception.param => 'is required'}, status: 422
  end
end
