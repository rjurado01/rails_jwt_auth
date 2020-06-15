if defined?(ActionMailer)
  class RailsJwtAuth::Mailer < ApplicationMailer
    default from: RailsJwtAuth.mailer_sender

    before_action do
      @user = RailsJwtAuth.model.find(params[:user_id])
      @subject = I18n.t("rails_jwt_auth.mailer.#{action_name}.subject")
    end

    def confirmation_instructions
      raise RailsJwtAuth::NotConfirmationsUrl unless RailsJwtAuth.confirmations_url.present?

      @confirmations_url = add_param_to_url(
        RailsJwtAuth.confirmations_url,
        'confirmation_token',
        @user.confirmation_token
      )

      mail(to: @user.unconfirmed_email || @user[RailsJwtAuth.email_field_name], subject: @subject)
    end

    def email_changed
      mail(to: @user[RailsJwtAuth.email_field_name!], subject: @subject)
    end

    def reset_password_instructions
      raise RailsJwtAuth::NotResetPasswordsUrl unless RailsJwtAuth.reset_passwords_url.present?

      @reset_passwords_url = add_param_to_url(
        RailsJwtAuth.reset_passwords_url,
        'reset_password_token',
        @user.reset_password_token
      )

      mail(to: @user[RailsJwtAuth.email_field_name], subject: @subject)
    end

    def set_password_instructions
      raise RailsJwtAuth::NotSetPasswordsUrl unless RailsJwtAuth.set_passwords_url.present?

      @reset_passwords_url = add_param_to_url(
        RailsJwtAuth.set_passwords_url,
        'reset_password_token',
        @user.reset_password_token
      )

      mail(to: @user[RailsJwtAuth.email_field_name], subject: @subject)
    end

    def send_invitation
      raise RailsJwtAuth::NotInvitationsUrl unless RailsJwtAuth.invitations_url.present?

      @invitations_url = add_param_to_url(
        RailsJwtAuth.invitations_url,
        'invitation_token',
        @user.invitation_token
      )

      mail(to: @user[RailsJwtAuth.email_field_name], subject: @subject)
    end

    def send_unlock_instructions
      @unlock_url = add_param_to_url(RailsJwtAuth.unlock_url, 'unlock_token', @user.unlock_token)

      mail(to: @user[RailsJwtAuth.email_field_name], subject: @subject)
    end

    protected

    def add_param_to_url(url, param_name, param_value)
      path, params = url.split '?'
      params = params ? params.split('&') : []
      params.push("#{param_name}=#{param_value}")
      "#{path}?#{params.join('&')}"
    end
  end
end
