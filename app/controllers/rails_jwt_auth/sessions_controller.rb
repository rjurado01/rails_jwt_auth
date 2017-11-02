require 'rails_jwt_auth/jwt/manager'
require 'rails_jwt_auth/jwt/request'

module RailsJwtAuth
  class SessionsController < ApplicationController
    include ParamsHelper
    include RenderHelper

    def create
      user = RailsJwtAuth.model.where(RailsJwtAuth.auth_field_name =>
        session_create_params[RailsJwtAuth.auth_field_name].to_s.downcase).first

      if !user
        render_422 session: [create_session_error]
      elsif user.respond_to?('confirmed?') && !user.confirmed?
        render_422 session: [I18n.t('rails_jwt_auth.errors.unconfirmed')]
      elsif user.authenticate(session_create_params[:password])
        render_session get_jwt(user), user
      else
        render_422 session: [create_session_error]
      end
    end

    def destroy
      authenticate!
      current_user.destroy_session Jwt::Request.new(request).session_id
      render_204
    end

    private

    def get_jwt(user)
      session = user.create_session(user_agent: request.user_agent, ip: request.remote_ip)
      RailsJwtAuth::Jwt::Manager.encode(session_id: session[:id])
    end

    def create_session_error
      I18n.t('rails_jwt_auth.errors.create_session', field: RailsJwtAuth.auth_field_name)
    end
  end
end
