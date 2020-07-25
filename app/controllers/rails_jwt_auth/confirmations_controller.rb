module RailsJwtAuth
  class ConfirmationsController < ApplicationController
    include ParamsHelper
    include RenderHelper

    before_action :set_user_from_token, only: [:show, :update]
    before_action :set_user_from_email, only: [:create]

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
      unless @user
        if RailsJwtAuth.avoid_email_errors
          return render_204
        else
          return render_422(RailsJwtAuth.email_field_name => [{error: :not_found}])
        end
      end

      @user.send_confirmation_instructions ? render_204 : render_422(@user.errors.details)
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


    def set_user_from_email
      email = (confirmation_create_params[RailsJwtAuth.email_field_name] || '').strip
      email.downcase! if RailsJwtAuth.downcase_auth_field

      if email.blank?
        return render_422(RailsJwtAuth.email_field_name => [{error: :blank}])
      elsif !email.match?(RailsJwtAuth.email_regex)
        return render_422(RailsJwtAuth.email_field_name => [{error: :format}])
      end

      @user = RailsJwtAuth.model.where(RailsJwtAuth.email_field_name => email).first
    end
  end
end
