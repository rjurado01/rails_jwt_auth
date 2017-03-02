module RailsJwtAuth
  class RegistrationsController < ApplicationController
    include RenderHelper

    def create
      user = RailsJwtAuth.model.new(create_params)

      user.save ? render_201(user) : render_422(user.errors)
    end

    private

    def create_params
      params.require(RailsJwtAuth.model_name.underscore).permit(
        RailsJwtAuth.auth_field_name, :password, :password_confirmation
      )
    end
  end
end
