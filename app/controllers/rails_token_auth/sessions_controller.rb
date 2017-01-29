class RailsTokenAuth::SessionsController < ApplicationController
  def create
    user = RTA.model.find_by(email: params[:email].to_s.downcase)

    if user && user.authenticate(params[:password])
      user.regenerate_auth_token
      token = JsonWebToken.encode({auth_token: user.auth_token})
      render json: create_success_response(user, token), status: 201
    else
      render json: create_error_response(user), status: 422
    end
  end

  def destroy
    authenticate!
    current_user.destroy_auth_token
  end

  private

  def create_success_response(user, token)
    {session: {auth_token: token}}
  end

  def create_error_response(user)
    {session: {error: 'Invalid email / password'}}
  end
end
