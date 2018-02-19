module RailsJwtAuth
  class InvitationsController < ApplicationController
    include ParamsHelper
    include RenderHelper

    def create
      attr_hash = invitation_create_params
      user = RailsJwtAuth.model.invite!(attr_hash)
      user.errors.empty? ? render_204 : render_422(user.errors)
    end

    def update
      attr_hash = invitation_update_params
      user = RailsJwtAuth.model.where(invitation_token: params[:id]).first
      user.assign_attributes attr_hash
      user.accept_invitation!

      return render_204 if user.errors.empty? && user.save

      render_422(user.errors)
    end
  end
end
