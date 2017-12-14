module RailsJwtAuth
  module ParamsHelper
    private

    def registration_create_params
      params.require(RailsJwtAuth.model_name.underscore).permit(
        RailsJwtAuth.auth_field_name, :password, :password_confirmation
      )
    end

    def confirmation_create_params
      params.require(:confirmation).permit(:email)
    end

    def session_create_params
      params.require(:session).permit(RailsJwtAuth.auth_field_name, :password)
    end

    def password_create_params
      params.require(:password).permit(:email)
    end

    def password_update_params
      params.require(:password).permit(:password, :password_confirmation)
    end

    def invitation_create_params
      params.require(:invitation).permit(:email)
    end

    def invitation_update_params
      params.require(:accept_invitation).permit(:invitation_token,
                                                :password,
                                                :password_confirmation)
    end
  end
end
