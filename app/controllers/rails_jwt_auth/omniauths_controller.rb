module RailsJwtAuth
  class OmniauthsController < ApplicationController
    include RenderHelper

    def callback
      user = RailsJwtAuth.model_name.constantize.from_omniauth(auth_hash)
      se = RailsJwtAuth::OmniauthSession.new(user)

      if se.generate!
        render_session se.jwt, se.user
      else
        render_422 se.errors.details
      end
    end

    protected

    def auth_hash
      request.env['omniauth.auth']
    end
  end
end