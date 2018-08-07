module RailsJwtAuth
  class PasswordsController < ApplicationController
    include ParamsHelper
    include RenderHelper

    def create
      user = RailsJwtAuth.model.where(email: password_create_params[:email].to_s.downcase).first
      return render_422(email: [{error: :not_found}]) unless user

      user.send_reset_password_instructions ? render_204 : render_422(user.errors.details)
    end

    def update
      return render_404 unless
        params[:id] &&
        (user = RailsJwtAuth.model.where(reset_password_token: params[:id]).first)

      return render_422(password: [{error: :blank}]) if password_update_params[:password].blank?

      user.update(password_update_params) ? render_204 : render_422(user.errors.details)
    end
  end
end
