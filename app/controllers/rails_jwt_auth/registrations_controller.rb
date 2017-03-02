module RailsJwtAuth
  class RegistrationsController < ApplicationController
    include ParamsHelper
    include RenderHelper

    def create
      user = RailsJwtAuth.model.new(registration_create_params)
      user.save ? render_201(user) : render_422(user.errors)
    end
  end
end
