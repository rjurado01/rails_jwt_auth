if defined?(ActionMailer)
  class RailsJwtAuth::Mailer < ApplicationMailer
    default from: RailsJwtAuth.mailer_sender

    before_action do
      @user = RailsJwtAuth.model.find(params[:user_id])
      @to = @user[RailsJwtAuth.email_field_name]
      @subject = I18n.t("rails_jwt_auth.mailer.#{action_name}.subject")
    end

    def confirmation_instructions
      raise RailsJwtAuth::NotConfirmationsUrl unless RailsJwtAuth.confirmations_url.present?

      @confirmations_url = add_param_to_url(
        RailsJwtAuth.confirmations_url,
        'confirmation_token',
        @user.confirmation_token
      )

      mail(to: @user.unconfirmed_email || @to, subject: @subject)
    end

    def email_change_notification
      mail(to: @to, subject: @subject)
    end

    def reset_password_instructions
      raise RailsJwtAuth::NotResetPasswordsUrl unless RailsJwtAuth.reset_passwords_url.present?

      @reset_passwords_url = add_param_to_url(
        RailsJwtAuth.reset_passwords_url,
        'reset_password_token',
        @user.reset_password_token
      )

      mail(to: @to, subject: @subject)
    end

    def password_changed_notification
      mail(to: @to, subject: @subject)
    end

    def invitation_instructions
      raise RailsJwtAuth::NotInvitationsUrl unless RailsJwtAuth.invitations_url.present?

      @invitations_url = add_param_to_url(
        RailsJwtAuth.invitations_url,
        'invitation_token',
        @user.invitation_token
      )

      mail(to: @to, subject: @subject)
    end

    def unlock_instructions
      raise RailsJwtAuth::NotUnlockUrl unless RailsJwtAuth.unlock_url.present?

      @unlock_url = add_param_to_url(RailsJwtAuth.unlock_url, 'unlock_token', @user.unlock_token)

      mail(to: @to, subject: @subject)
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
