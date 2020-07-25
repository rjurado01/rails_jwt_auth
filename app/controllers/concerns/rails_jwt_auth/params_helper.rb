module RailsJwtAuth
  module ParamsHelper
    private

    def registration_create_params
      params.require(RailsJwtAuth.model_name.underscore).permit(
        RailsJwtAuth.auth_field_name, :password, :password_confirmation
      )
    end

    def confirmation_create_params
      params.require(:confirmation).permit(RailsJwtAuth.email_field_name)
    end

    def session_create_params
      params.require(:session).permit(RailsJwtAuth.auth_field_name, :password)
    end

    def reset_password_create_params
      params.require(:reset_password).permit(RailsJwtAuth.email_field_name)
    end

    def reset_password_update_params
      params.require(:reset_password).permit(:password, :password_confirmation)
    end

    def invitation_create_params
      params.require(:invitation).permit(RailsJwtAuth.email_field_name)
    end

    def invitation_update_params
      params.require(:invitation).permit(:password, :password_confirmation)
    end

    def profile_update_params
      params.require(:profile).except(
        RailsJwtAuth.auth_field_name, :current_password, :password, :password_confirmation
      )
    end

    def profile_update_password_params
      params.require(:profile).permit(:current_password, :password, :password_confirmation)
    end

    def profile_update_email_params
      params.require(:profile).permit(RailsJwtAuth.auth_field_name, :password)
    end
  end
end
