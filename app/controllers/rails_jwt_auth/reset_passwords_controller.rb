module RailsJwtAuth
  class ResetPasswordsController < ApplicationController
    include ParamsHelper
    include RenderHelper

    before_action :set_user_from_token, only: [:show, :update]
    before_action :set_user_from_email, only: [:create]

    # used to verify token
    def show
      return render_404 unless @user

      if @user.reset_password_sent_at < RailsJwtAuth.reset_password_expiration_time.ago
        return render_410
      end

      render_204
    end

    # used to request restore password
    def create
      unless @user
        if RailsJwtAuth.avoid_email_errors
          return render_204
        else
          return render_422(RailsJwtAuth.email_field_name => [{error: :not_found}])
        end
      end

      @user.send_reset_password_instructions ? render_204 : render_422(@user.errors.details)
    end

    # used to set new password
    def update
      return render_404 unless @user

      if @user.set_reset_password(reset_password_update_params)
        render_204
      else
        render_422(@user.errors.details)
      end
    end

    private

    def set_user_from_token
      return if params[:id].blank?

      @user = RailsJwtAuth.model.where(reset_password_token: params[:id]).first
    end

    def set_user_from_email
      email = (reset_password_create_params[RailsJwtAuth.email_field_name] || '').strip
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
