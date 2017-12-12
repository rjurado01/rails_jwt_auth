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
      token = attr_hash.delete(:invitation_token)
      user = RailsJwtAuth.model.where(invitation_token: token).first
      user.assign_attributes attr_hash
      user.accept_invitation!

      if user.errors.empty? && user.save
        return render_204
      else
        user.update_attribute :invitation_token, token
        return render_422(user.errors)
      end
    end
  end
end
