module RailsJwtAuth
  class InvitationsController < ApplicationController
    include ParamsHelper
    include RenderHelper

    def create
      user = RailsJwtAuth.model.invite!(invitation_create_params)
      user.errors.empty? ? render_204 : render_422(user.errors.details)
    end

    def update
      return render_404 unless
        params[:id] &&
        (user = RailsJwtAuth.model.where(invitation_token: params[:id]).first)

      user.assign_attributes invitation_update_params
      user.accept_invitation!
      return render_204 if user.errors.empty? && user.save

      render_422(user.errors.details)
    end
  end
end
