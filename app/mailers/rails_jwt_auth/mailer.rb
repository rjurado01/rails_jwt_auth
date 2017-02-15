if defined?(ActionMailer)
  class RailsJwtAuth::Mailer < ApplicationMailer
    default from: RailsJwtAuth.mailer_sender

    def confirmation_instructions(user)
      @user = user

      if (@url = RailsJwtAuth.confirmation_url)
        @url = URI.parse(@url)
        @url.query = [@url.query, "confirmation_token=#{@user.confirmation_token}"].compact.join('&')
        @url = @url.to_s
      end

      subject = I18n.t('rails_jwt_auth.mailer.confirmation_instructions.subject')
      mail(to: @user.email, subject: subject)
    end
  end
end
