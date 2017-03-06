module RailsJwtAuth
  class PasswordsController < ApplicationController
    include ParamsHelper
    include RenderHelper

    def create
      user = RailsJwtAuth.model.where(email: password_create_params[:email]).first
      return render_422(email: [I18n.t('rails_jwt_auth.errors.not_found')]) unless user

      user.send_reset_password_instructions ? render_204 : render_422(user.errors)
    end

    def update
      user = RailsJwtAuth.model.where(reset_password_token: params[:reset_password_token]).first

      unless user
        return render_422(reset_password_token: [I18n.t('rails_jwt_auth.errors.not_found')])
      end

      unless password_update_params[:password].present?
        return render_422(password: [I18n.t('rails_jwt_auth.errors.invalid')])
      end

      user.update_attributes(password_update_params) ? render_204 : render_422(user.errors)
    end
  end
end
