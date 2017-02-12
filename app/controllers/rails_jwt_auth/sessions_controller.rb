require 'rails_jwt_auth/jwt/manager'
require 'rails_jwt_auth/jwt/request'

module RailsJwtAuth
  class SessionsController < ApplicationController
    def create
      user = RailsJwtAuth.model.where(
        RailsJwtAuth.auth_field_name => params[RailsJwtAuth.auth_field_name].to_s.downcase
      ).first

      if user && user.authenticate(params[:password])
        token = user.regenerate_auth_token
        jwt = RailsJwtAuth::Jwt::Manager.encode(auth_token: token)
        render json: create_success_response(user, jwt), status: 201
      else
        render json: create_error_response(user), status: 422
      end
    end

    def destroy
      authenticate!
      current_user.destroy_auth_token Jwt::Request.new(request).auth_token
    end

    private

    def create_success_response(_user, jwt)
      {session: {jwt: jwt}}
    end

    def create_error_response(_user)
      {session: {error: "Invalid #{RailsJwtAuth.auth_field_name} / password"}}
    end
  end
end
