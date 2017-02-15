class RailsJwtAuth::ConfirmationsController < ApplicationController
  def show
    unless token = params[:confirmation_token]
      return render json: {}, status: 400
    end

    user = RailsJwtAuth.model.find_by!(confirmation_token: token)

    if user.confirm!
      render json: {}, status: 204
    else
      render json: {errors: user.errors}, status: 422
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
end
