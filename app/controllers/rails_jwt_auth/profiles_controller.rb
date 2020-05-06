module RailsJwtAuth
  class ProfilesController < ApplicationController
    include ParamsHelper
    include RenderHelper

    PASSWORD_PARAMS = %i[current_password password password_confirmation]

    before_action :authenticate!

    def show
      render_profile current_user
    end

    def update
      result = if changing_password?
                 current_user.update_with_password(profile_update_params)
               else
                 current_user.update(profile_update_params.except(*PASSWORD_PARAMS))
               end

      result ? render_204 : render_422(current_user.errors.details)
    end

    protected

    def changing_password?
      profile_update_params.values_at(*PASSWORD_PARAMS).any?(&:present?)
    end
  end
end
