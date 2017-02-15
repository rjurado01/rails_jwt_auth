class RailsJwtAuth::RegistrationsController < ApplicationController
  def create
    user = RailsJwtAuth.model.new(create_params)

    if user.save
      render json: create_success_response(user), status: 201
    else
      render json: create_error_response(user), status: 422
    end
  end

  private

  def root
    RailsJwtAuth.model_name.underscore
  end

  def create_success_response(user)
    {
      root => {
        id: user.id.to_s,
        RailsJwtAuth.auth_field_name => user.send(RailsJwtAuth.auth_field_name)
      }
    }
  end

  def create_error_response(user)
    {errors: user.errors}
  end

  def create_params
    params.require(root).permit(
      RailsJwtAuth.auth_field_name, :password, :password_confirmation)
  end
end
