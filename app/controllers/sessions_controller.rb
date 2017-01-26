class SessionsController < ApplicationController
  def create
    user = User.find_by(email: params[:email].to_s.downcase)

    if user && user.authenticate(params[:password])
      user.regenerate_auth_token
      jwt_token = JsonWebToken.encode({auth_token: user.auth_token})
      render json: {auth_token: jwt_token}, status: :ok
    else
      render json: {error: 'Invalid username / password'}, status: :unauthorized
    end
  end

  def destroy
    authenticate!
    current_user.destroy_auth_token
  end
end
