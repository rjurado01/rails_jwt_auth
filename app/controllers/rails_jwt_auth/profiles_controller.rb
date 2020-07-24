module RailsJwtAuth
  class ProfilesController < ApplicationController
    include ParamsHelper
    include RenderHelper

    PASSWORD_PARAMS = %i[current_password password password_confirmation].freeze

    before_action :authenticate!

    def show
      render_profile current_user
    end

    def update
      if current_user.update(profile_update_params)
        render_204
      else
        render_422(current_user.errors.details)
      end
    end

    def password
      if current_user.update_password(update_password_params)
        render_204
      else
        render_422(current_user.errors.details)
      end
    end

    def email
      return update unless current_user.is_a?(RailsJwtAuth::Confirmable)

      if current_user.update_email(profile_update_email_params)
        render_204
      else
        render_422(current_user.errors.details)
      end
    end

    protected

    def changing_password?
      profile_update_params.values_at(*PASSWORD_PARAMS).any?(&:present?)
    end

    def update_password_params
      profile_update_password_params.merge(current_auth_token: jwt_payload['auth_token'])
    end
  end
end
