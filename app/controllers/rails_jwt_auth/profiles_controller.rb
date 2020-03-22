module RailsJwtAuth
  class ProfilesController < ApplicationController
    include ParamsHelper
    include RenderHelper

    before_action :authenticate!

    def show
      render_profile current_user
    end

    def update
      result = if changing_password?
                current_user.update_with_password(profile_update_params)
              else
                current_user.update(profile_update_params)
              end

      result ? render_204 : render_422(current_user.errors.details)
    end

    protected

    def changing_password?
      profile_update_params.values_at(:current_password, :password, :password_confirmation).any?
    end
  end
end
