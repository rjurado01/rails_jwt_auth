module RailsJwtAuth
  class ConfirmationsController < ApplicationController
    include ParamsHelper
    include RenderHelper

    before_action :set_user_from_token, only: [:show, :update]

    # used to verify token
    def show
      return render_404 unless @user

      if user.confirmation_sent_at < RailsJwtAuth.confirmation_expiration_time.ago
        return render_410
      end

      render_204
    end

    # used to resend confirmation
    def create
      user = RailsJwtAuth.model.where(
        email: confirmation_create_params[RailsJwtAuth.email_field_name]
      ).first

      return render_422(email: [{error: :not_found}]) unless user

      user.send_confirmation_instructions ? render_204 : render_422(user.errors.details)
    end

    # used to accept confirmation
    def update
      return render_404 unless @user

      @user.confirm ? render_204 : render_422(@user.errors.details)
    end

    private

    def set_user_from_token
      return if params[:id].blank?

      @user = RailsJwtAuth.model.where(confirmation_token: params[:id]).first
    end
  end
end
