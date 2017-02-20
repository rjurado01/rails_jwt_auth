if defined?(ActionMailer)
  class RailsJwtAuth::Mailer < ApplicationMailer
    default from: RailsJwtAuth.mailer_sender

    def confirmation_instructions(user)
      return unless user.confirmation_in_progress?
      @user = user

      if RailsJwtAuth.confirmation_url
        url = URI.parse(RailsJwtAuth.confirmation_url)
        url.query = [url.query, "confirmation_token=#{@user.confirmation_token}"].compact.join('&')
        @confirmation_url = url.to_s
      else
        @confirmation_url = confirmation_url(confirmation_token: @user.confirmation_token)
      end

      subject = I18n.t('rails_jwt_auth.mailer.confirmation_instructions.subject')
      mail(to: @user.email, subject: subject)
    end

    def reset_password_instructions(user)
      return unless user.reset_password_in_progress?
      @user = user

      if RailsJwtAuth.reset_password_url
        url = URI.parse(RailsJwtAuth.reset_password_url)
        url.query = [url.query, "reset_password_token=#{@user.reset_password_token}"].compact.join('&')
        @reset_password_url = url.to_s
      else
        @reset_password_url = password_url(reset_password_token: @user.reset_password_token)
      end

      subject = I18n.t('rails_jwt_auth.mailer.reset_password_instructions.subject')
      mail(to: @user.email, subject: subject)
    end
  end
end
