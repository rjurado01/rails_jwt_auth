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
      return render_422(reset_password_token: [I18n.t('rails_jwt_auth.errors.not_found')]) unless user

      user.update_attributes(password_update_params) ? render_204 : render_422(user.errors)
    end
  end
end
