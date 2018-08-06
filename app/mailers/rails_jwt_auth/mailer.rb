if defined?(ActionMailer)
  class RailsJwtAuth::Mailer < ApplicationMailer
    default from: RailsJwtAuth.mailer_sender

    def confirmation_instructions(user)
      raise RailsJwtAuth::NotConfirmationsUrl unless RailsJwtAuth.confirmations_url.present?
      @user = user

      url, params = RailsJwtAuth.confirmations_url.split('?')
      params = params ? params.split('&') : []
      params.push("confirmation_token=#{@user.confirmation_token}")
      @confirmations_url = "#{url}?#{params.join('&')}"

      subject = I18n.t('rails_jwt_auth.mailer.confirmation_instructions.subject')
      mail(to: @user.unconfirmed_email || @user[RailsJwtAuth.email_field_name], subject: subject)
    end

    def reset_password_instructions(user)
      raise RailsJwtAuth::NotResetPasswordsUrl unless RailsJwtAuth.reset_passwords_url.present?
      @user = user

      url, params = RailsJwtAuth.reset_passwords_url.split('?')
      params = params ? params.split('&') : []
      params.push("reset_password_token=#{@user.reset_password_token}")
      @reset_passwords_url = "#{url}?#{params.join('&')}"

      subject = I18n.t('rails_jwt_auth.mailer.reset_password_instructions.subject')
      mail(to: @user[RailsJwtAuth.email_field_name], subject: subject)
    end

    def set_password_instructions(user)
      raise RailsJwtAuth::NotSetPasswordsUrl unless RailsJwtAuth.set_passwords_url.present?
      @user = user

      url, params = RailsJwtAuth.set_passwords_url.split('?')
      params = params ? params.split('&') : []
      params.push("reset_password_token=#{@user.reset_password_token}")
      @reset_passwords_url = "#{url}?#{params.join('&')}"

      subject = I18n.t('rails_jwt_auth.mailer.set_password_instructions.subject')
      mail(to: @user[RailsJwtAuth.email_field_name], subject: subject)
    end

    def send_invitation(user)
      raise RailsJwtAuth::NotInvitationsUrl unless RailsJwtAuth.invitations_url.present?
      @user = user

      url, params = RailsJwtAuth.invitations_url.split '?'
      params = params ? params.split('&') : []
      params.push("invitation_token=#{@user.invitation_token}")
      @invitations_url = "#{url}?#{params.join('&')}"

      subject = I18n.t('rails_jwt_auth.mailer.send_invitation.subject')
      mail(to: @user[RailsJwtAuth.email_field_name], subject: subject)
    end
  end
end
