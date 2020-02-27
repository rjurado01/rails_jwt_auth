module RailsJwtAuth
  class SessionsController < ApplicationController
    include ParamsHelper
    include RenderHelper

    def create
      se = Session.new(session_create_params)

      if se.valid?
        render_session generate_jwt(se.user), se.user
      else
        render_422 se.errors.details
      end
    end

    def destroy
      return render_404 unless RailsJwtAuth.simultaneous_sessions > 0

      authenticate!
      payload = JwtManager.decode_from_request(request)&.first
      current_user.destroy_auth_token payload['auth_token']
      render_204
    end

    private

    def generate_jwt(user)
      JwtManager.encode(user.to_token_payload(request))
    end
  end
end
