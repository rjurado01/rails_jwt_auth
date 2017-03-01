class RailsJwtAuth::PasswordsController < ApplicationController
  def create
    user = RailsJwtAuth.model.where(email: create_password_params[:email]).first
    return render json: create_error_response, status: 422 unless user

    user.send_reset_password_instructions
    render json: {}, status: 204
  end

  def update
    user = RailsJwtAuth.model.where(reset_password_token: params[:reset_password_token]).first
    return render json: update_error_response(nil), status: 422 unless user

    if user.update_attributes(update_password_params)
      render json: {}, status: 204
    else
      render json: update_error_response(user), status: 422
    end
  end

  private

  def create_password_params
    params.require(:password).permit(:email)
  end

  def create_error_response
    {errors: {email: [I18n.t('rails_jwt_auth.errors.not_found')]}}
  end

  def update_password_params
    params.require(:password).permit(:password, :password_confirmation)
  end

  def update_error_response(user)
    if user
      {errors: user.errors}
    else
      {errors: {reset_password_token: [I18n.t('rails_jwt_auth.errors.not_found')]}}
    end
  end
end
