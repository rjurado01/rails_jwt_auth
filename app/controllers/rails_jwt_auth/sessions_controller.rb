module RailsJwtAuth
  class SessionsController < ApplicationController
    include ParamsHelper
    include RenderHelper

    def create
      se = Session.new(session_create_params)

      if se.generate!(request)
        render_session se.jwt, se.user
      else
        render_422 se.errors.details
      end
    end

    def destroy
      return render_404 unless RailsJwtAuth.simultaneous_sessions > 0

      authenticate!
      current_user.destroy_auth_token @jwt_payload['auth_token']
      render_204
    end
  end
end
