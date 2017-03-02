module RailsJwtAuth
  class ConfirmationsController < ApplicationController
    include RenderHelper

    def create
      user = RailsJwtAuth.model.where(email: confirmation_params[:email]).first
      return render_422(email: [I18n.t('rails_jwt_auth.errors.not_found')]) unless user

      user.send_confirmation_instructions ? render_204 : render_422(user.errors)
    end

    def update
      user = RailsJwtAuth.model.where(confirmation_token: params[:confirmation_token]).first
      return render_422(confirmation_token: [I18n.t('rails_jwt_auth.errors.not_found')]) unless user

      user.confirm! ? render_204 : render_422(user.errors)
    end

    private

    def confirmation_params
      params.require(:confirmation).permit(:email)
    end
  end
end
