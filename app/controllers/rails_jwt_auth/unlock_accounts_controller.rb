module RailsJwtAuth
  class UnlockAccountsController < ApplicationController
    include ParamsHelper
    include RenderHelper

    def update
      return render_404 unless
        params[:id] &&
        (user = RailsJwtAuth.model.where(unlock_token: params[:id]).first)

      user.unlock_access ? render_204 : render_422(user.errors.details)
    end
  end
end
