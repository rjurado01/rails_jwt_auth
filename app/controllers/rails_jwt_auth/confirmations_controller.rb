class RailsJwtAuth::ConfirmationsController < ApplicationController
  def show
    return render json: {}, status: 400 unless params[:confirmation_token]

    user = RailsJwtAuth.model.find_by!(confirmation_token: params[:confirmation_token])

    if user.confirm!
      render json: {}, status: 204
    else
      render json: show_error_response(user), status: 422
    end
  end

  def create
    unless (user = RailsJwtAuth.model.where(email: confirmation_params[:email]).first)
      return render json: create_error_response, status: 422
    end

    user.send_confirmation_instructions
    render json: {}, status: 204
  end

  private

  def confirmation_params
    params.require(:confirmation).permit(:email)
  end

  def show_error_response(user)
    {errors: user.errors}
  end

  def create_error_response
    {errors: {email: [I18n.t('rails_jwt_auth.errors.not_found')]}}
  end
end
