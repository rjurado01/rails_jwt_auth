if defined?(ActionMailer)
  class RailsJwtAuth::Mailer < ApplicationMailer
    default from: RailsJwtAuth.mailer_sender

    def confirmation_instructions(user)
      @user = user

      if RailsJwtAuth.confirmation_url
        url, params = RailsJwtAuth.confirmation_url.split('?')
        params = params ? params.split('&') : []
        params.push("confirmation_token=#{@user.confirmation_token}")

        @confirmation_url = "#{url}?#{params.join('&')}"
      else
        @confirmation_url = confirmation_url(confirmation_token: @user.confirmation_token)
      end

      subject = I18n.t('rails_jwt_auth.mailer.confirmation_instructions.subject')
      mail(to: @user.unconfirmed_email || @user[RailsJwtAuth.email_field_name], subject: subject)
    end

    def reset_password_instructions(user)
      @user = user

      if RailsJwtAuth.reset_password_url
        url, params = RailsJwtAuth.reset_password_url.split('?')
        params = params ? params.split('&') : []
        params.push("reset_password_token=#{@user.reset_password_token}")

        @reset_password_url = "#{url}?#{params.join('&')}"
      else
        @reset_password_url = password_url(reset_password_token: @user.reset_password_token)
      end

      subject = I18n.t('rails_jwt_auth.mailer.reset_password_instructions.subject')
      mail(to: @user[RailsJwtAuth.email_field_name], subject: subject)
    end

    def set_password_instructions(user)
      @user = user

      if RailsJwtAuth.set_password_url
        url, params = RailsJwtAuth.set_password_url.split('?')
        params = params ? params.split('&') : []
        params.push("reset_password_token=#{@user.reset_password_token}")

        @reset_password_url = "#{url}?#{params.join('&')}"
      else
        @reset_password_url = password_url(reset_password_token: @user.reset_password_token)
      end

      subject = I18n.t('rails_jwt_auth.mailer.set_password_instructions.subject')
      mail(to: @user[RailsJwtAuth.email_field_name], subject: subject)
    end

    def send_invitation(user)
      @user = user

      if RailsJwtAuth.accept_invitation_url
        url, params = RailsJwtAuth.accept_invitation_url.split '?'
        params = params ? params.split('&') : []
        params.push("invitation_token=#{@user.invitation_token}")
        @accept_invitation_url = "#{url}?#{params.join('&')}"
      else
        @accept_invitation_url = invitations_url(invitation_token: @user.invitation_token)
      end

      subject = I18n.t('rails_jwt_auth.mailer.send_invitation.subject')
      mail(to: @user[RailsJwtAuth.email_field_name], subject: subject)
    end
  end
end
