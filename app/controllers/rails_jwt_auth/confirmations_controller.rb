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
    user = RailsJwtAuth.model.find_by!(email: confirmation_params[:email])
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
end
