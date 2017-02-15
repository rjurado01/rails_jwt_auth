require 'rails_helper'

RSpec.describe RailsJwtAuth::Mailer, type: :mailer do
  let(:user) { FactoryGirl.create(:active_record_user) }

  describe 'confirmation_instructions' do
    let(:mail) { described_class.confirmation_instructions(user).deliver_now }

    it 'sends email with correct info' do
      expect { mail }.to change { ActionMailer::Base.deliveries.count }.by(1)
      expect(mail.subject).to eq(I18n.t('rails_jwt_auth.mailer.confirmation_instructions.subject'))
      expect(mail.to).to include(user.email)
      expect(mail.from).to include(RailsJwtAuth.mailer_sender)
      expect(mail.body).to include(confirmation_url(confirmation_token: user.confirmation_token))
    end

    context 'when confirmation_url opton is defined' do
      before do
        RailsJwtAuth.confirmation_url = 'http://my-url.com'
      end

      it 'uses this to generate confirmation url' do
        url = "#{RailsJwtAuth.confirmation_url}?confirmation_token=#{user.confirmation_token}"
        expect(mail.body).to include(url)
      end
    end
  end
end
