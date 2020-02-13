if defined?(ActionMailer)
  class RailsJwtAuth::Mailer < ApplicationMailer
    default from: RailsJwtAuth.mailer_sender

    def confirmation_instructions(user)
      raise RailsJwtAuth::NotConfirmationsUrl unless RailsJwtAuth.confirmations_url.present?
      @user = user

      @confirmations_url = add_param_to_url(
        RailsJwtAuth.confirmations_url,
        'confirmation_token',
        @user.confirmation_token
      )

      subject = I18n.t('rails_jwt_auth.mailer.confirmation_instructions.subject')
      mail(to: @user.unconfirmed_email || @user[RailsJwtAuth.email_field_name], subject: subject)
    end

    def email_changed(user)
      @user = user
      subject = I18n.t('rails_jwt_auth.mailer.email_changed.subject')
      mail(to: @user[RailsJwtAuth.email_field_name!], subject: subject)
    end

    def reset_password_instructions(user)
      raise RailsJwtAuth::NotResetPasswordsUrl unless RailsJwtAuth.reset_passwords_url.present?
      @user = user

      @reset_passwords_url = add_param_to_url(
        RailsJwtAuth.reset_passwords_url,
        'reset_password_token',
        @user.reset_password_token
      )

      subject = I18n.t('rails_jwt_auth.mailer.reset_password_instructions.subject')
      mail(to: @user[RailsJwtAuth.email_field_name], subject: subject)
    end

    def send_invitation(user)
      raise RailsJwtAuth::NotInvitationsUrl unless RailsJwtAuth.invitations_url.present?
      @user = user

      @invitations_url = add_param_to_url(
        RailsJwtAuth.invitations_url,
        'invitation_token',
        @user.invitation_token
      )

      subject = I18n.t('rails_jwt_auth.mailer.send_invitation.subject')
      mail(to: @user[RailsJwtAuth.email_field_name], subject: subject)
    end

    def send_unlock_instructions(user)
      @user = user
      subject = I18n.t('rails_jwt_auth.mailer.send_unlock_instructions.subject')

      @unlock_url = add_param_to_url(RailsJwtAuth.unlock_url, 'unlock_token', @user.unlock_token)

      mail(to: @user[RailsJwtAuth.email_field_name], subject: subject)
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
