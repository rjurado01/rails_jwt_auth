class RailsJwtAuth::ConfirmationsController < ApplicationController
  def create
    user = RailsJwtAuth.model.where(email: confirmation_params[:email]).first
    return render json: create_error_response, status: 422 unless user

    user.send_confirmation_instructions
    render json: {}, status: 204
  end

  def update
    user = RailsJwtAuth.model.where(confirmation_token: params[:confirmation_token]).first
    return render json: update_error_response(nil), status: 422 unless user

    if user.confirm!
      render json: {}, status: 204
    else
      render json: update_error_response(user), status: 422
    end
  end

  private

  def confirmation_params
    params.require(:confirmation).permit(:email)
  end

  def create_error_response
    {errors: {email: [I18n.t('rails_jwt_auth.errors.not_found')]}}
  end

  def update_error_response(user)
    if user
      {errors: user.errors}
    else
      {errors: {confirmation_token: [I18n.t('rails_jwt_auth.errors.not_found')]}}
    end
  end
end
