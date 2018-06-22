module RailsJwtAuth
  class ConfirmationsController < ApplicationController
    include ParamsHelper
    include RenderHelper

    def create
      user = RailsJwtAuth.model.where(email: confirmation_create_params[:email]).first
      return render_422(email: [{error: :not_found}]) unless user

      user.send_confirmation_instructions ? render_204 : render_422(user.errors.details)
    end

    def update
      if params[:confirmation_token].blank?
        return render_422(confirmation_token: [{error: :not_found}])
      end

      user = RailsJwtAuth.model.where(confirmation_token: params[:confirmation_token]).first
      return render_422(confirmation_token: [{error: :not_found}]) unless user

      user.confirm! ? render_204 : render_422(user.errors.details)
    end
  end
end
