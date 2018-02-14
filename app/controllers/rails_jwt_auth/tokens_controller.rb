require 'rails_jwt_auth/jwt_manager'

module RailsJwtAuth
  class TokensController < ApplicationController
    include ParamsHelper
    include RenderHelper

    def create
      user = RailsJwtAuth.model.where(RailsJwtAuth.auth_field_name =>
        token_create_params[RailsJwtAuth.auth_field_name].to_s.downcase).first

      if !user || !user.authenticate(token_create_params[:password])
        render_422 token: [create_token_error]
      elsif user.respond_to?('confirmed?') && !user.confirmed?
        render_422 token: [I18n.t('rails_jwt_auth.errors.unconfirmed')]
      else
        render_token create_token(user)
      end
    end

    private

    def create_token(user)
      payload = user.to_token_payload request
      RailsJwtAuth::JwtManager.encode(payload)
    end

    def create_token_error
      I18n.t('rails_jwt_auth.errors.create_token', field: RailsJwtAuth.auth_field_name)
    end
  end
end
