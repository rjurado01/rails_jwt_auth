class ApplicationController < ActionController::Base
  include RailsJwtAuth::AuthenticableHelper

  protect_from_forgery with: :exception

  rescue_from ActionController::ParameterMissing do |exception|
    render json: {exception.param => 'is required'}, status: 422
  end

  rescue_from ActiveRecord::RecordNotFound do
    render json: {}, status: 404
  end

  rescue_from Mongoid::Errors::DocumentNotFound do
    render json: {}, status: 404
  end

  rescue_from RailsJwtAuth::NotAuthorized do
    render json: {}, status: 401
  end
end
