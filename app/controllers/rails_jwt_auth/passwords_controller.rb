class RailsJwtAuth::PasswordsController < ApplicationController
  def create
    user = RailsJwtAuth.model.find_by!(email: create_password_params[:email])
    user.send_reset_password_instructions
    render json: {}, status: 204
  end

  def update
    user = RailsJwtAuth.model.find_by!(reset_password_token: params[:reset_password_token])

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

  def update_password_params
    params.require(:password).permit(:password, :password_confirmation)
  end

  def update_error_response(user)
    {errors: user.errors}
  end
end
