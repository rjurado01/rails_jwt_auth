require 'rails_helper'

RSpec.describe RailsJwtAuth::Mailer, type: :mailer do
  describe 'confirmation_instructions' do
    let(:user) do
      FactoryBot.create(:active_record_unconfirmed_user,
                         confirmation_token: 'abcd', confirmation_sent_at: Time.current)
    end

    let(:mail) { described_class.confirmation_instructions(user).deliver_now }
    let(:url) { "#{RailsJwtAuth.confirmations_url}?confirmation_token=#{user.confirmation_token}" }

    it 'sends email with correct info' do
      expect { mail }.to change { ActionMailer::Base.deliveries.count }.by(1)
      expect(mail.subject).to eq(I18n.t('rails_jwt_auth.mailer.confirmation_instructions.subject'))
      expect(mail.to).to include(user.email)
      expect(mail.from).to include(RailsJwtAuth.mailer_sender)
      expect(mail.body).to include(url)
    end

    context 'when confirmations_url option is defined with hash url' do
      before do
        RailsJwtAuth.confirmations_url = 'http://www.host.com/#/url?param=value'
      end

      it 'uses this to generate confirmation url' do
        url = "#{RailsJwtAuth.confirmations_url}&confirmation_token=#{user.confirmation_token}"
        expect(mail.body).to include(url)
      end
    end

    context 'when model has unconfirmed_email' do
      it 'sends email with correct info' do
        user.email = 'new@email.com'
        user.save
        expect { mail }.to change { ActionMailer::Base.deliveries.count }.by(1)
        expect(mail.subject).to eq(I18n.t('rails_jwt_auth.mailer.confirmation_instructions.subject'))
        expect(mail.to).to include('new@email.com')
      end
    end
  end

  describe 'reset_password_instructions' do
    let(:user) do
      FactoryBot.create(:active_record_user, reset_password_token: 'abcd',
                                             reset_password_sent_at: Time.current)
    end

    let(:mail) { described_class.reset_password_instructions(user).deliver_now }
    let(:url) { "#{RailsJwtAuth.reset_passwords_url}?reset_password_token=#{user.reset_password_token}" }

    it 'sends email with correct info' do
      expect { mail }.to change { ActionMailer::Base.deliveries.count }.by(1)
      expect(mail.subject).to eq(I18n.t('rails_jwt_auth.mailer.reset_password_instructions.subject'))
      expect(mail.to).to include(user.email)
      expect(mail.from).to include(RailsJwtAuth.mailer_sender)
      expect(mail.body).to include(url)
    end

    context 'when reset_passwords_url option is defined with hash url' do
      before do
        RailsJwtAuth.reset_passwords_url = 'http://www.host.com/#/url?param=value'
      end

      it 'uses this to generate confirmation url' do
        url = "#{RailsJwtAuth.reset_passwords_url}&reset_password_token=#{user.reset_password_token}"
        expect(mail.body).to include(url)
      end
    end
  end

  describe 'set_password_instructions' do
    let(:user) do
      FactoryBot.create(:active_record_user, reset_password_token: 'abcd',
                                             reset_password_sent_at: Time.current)
    end

    let(:mail) { described_class.set_password_instructions(user).deliver_now }
    let(:url) { "#{RailsJwtAuth.set_passwords_url}?reset_password_token=#{user.reset_password_token}" }

    it 'sends email with correct info' do
      expect { mail }.to change { ActionMailer::Base.deliveries.count }.by(1)
      expect(mail.subject).to eq(I18n.t('rails_jwt_auth.mailer.set_password_instructions.subject'))
      expect(mail.to).to include(user.email)
      expect(mail.from).to include(RailsJwtAuth.mailer_sender)
      expect(mail.body).to include(url)
    end

    context 'when set_passwords_url option is defined with hash url' do
      before do
        RailsJwtAuth.set_passwords_url = 'http://www.host.com/#/url?param=value'
      end

      it 'uses this to generate confirmation url' do
        url = "#{RailsJwtAuth.set_passwords_url}&reset_password_token=#{user.reset_password_token}"
        expect(mail.body).to include(url)
      end
    end
  end

  describe 'send_invitation' do
    let(:user) do
      FactoryBot.create(:active_record_user, invitation_token: 'abcd',
                                             invitation_created_at: Time.current)
    end

    let(:mail) { described_class.send_invitation(user).deliver_now }
    let(:url) { "#{RailsJwtAuth.invitations_url}?invitation_token=#{user.invitation_token}" }

    it 'sends email with correct info' do
      expect { mail }.to change { ActionMailer::Base.deliveries.count }.by(1)
      expect(mail.subject).to eq(I18n.t('rails_jwt_auth.mailer.send_invitation.subject'))
      expect(mail.to).to include(user.email)
      expect(mail.from).to include(RailsJwtAuth.mailer_sender)
      expect(mail.body).to include(url)
    end

    context 'when invitations_url option is defined with hash url' do
      before do
        RailsJwtAuth.invitations_url = 'http://www.host.com/#/url?param=value'
      end

      it 'uses this to generate invitation url' do
        url = "#{RailsJwtAuth.invitations_url}&invitation_token=#{user.invitation_token}"
        expect(mail.body).to include(url)
      end
    end
  end
end
