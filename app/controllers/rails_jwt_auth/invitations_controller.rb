module RailsJwtAuth
  class InvitationsController < ApplicationController
    include ParamsHelper
    include RenderHelper

    before_action :load_user, only: [:update]

    def create
      authenticate!
      user = RailsJwtAuth.model.invite!(invitation_create_params)
      user.errors.empty? ? render_204 : render_422(user.errors.details)
    end

    def update
      return render_404 unless @user

      if @user.accept_invitation!(invitation_update_params)
        render_204
      else
        render_422(@user.errors.details)
      end
    end

    private

    def load_user
      return unless params[:id]

      @user = RailsJwtAuth.model.where(invitation_token: params[:id]).first
    end
  end
end
