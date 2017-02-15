require 'rails_jwt_auth/jwt/manager'
require 'rails_jwt_auth/jwt/request'

module RailsJwtAuth
  class SessionsController < ApplicationController
    def create
      user = RailsJwtAuth.model.where(
        RailsJwtAuth.auth_field_name => create_params[RailsJwtAuth.auth_field_name].to_s.downcase
      ).first

      if !user
        render json: create_error_response(user), status: 422
      elsif user.respond_to?('confirmed?') && !user.confirmed?
        render json: unconfirmed_error_response, status: 422
      elsif user.authenticate(create_params[:password])
        render json: create_success_response(user, get_jwt(user)), status: 201
      else
        render json: create_error_response(user), status: 422
      end
    end

    def destroy
      authenticate!
      current_user.destroy_auth_token Jwt::Request.new(request).auth_token
    end

    private

    def get_jwt(user)
      token = user.regenerate_auth_token
      RailsJwtAuth::Jwt::Manager.encode(auth_token: token)
    end

    def unconfirmed_error_response
      {errors: {session: 'Unconfirmed email'}}
    end

    def create_success_response(_user, jwt)
      {session: {jwt: jwt}}
    end

    def create_error_response(_user)
      {errors: {session: "Invalid #{RailsJwtAuth.auth_field_name} / password"}}
    end

    def create_params
      params.require(:session).permit(RailsJwtAuth.auth_field_name, :password)
    end
  end
end
