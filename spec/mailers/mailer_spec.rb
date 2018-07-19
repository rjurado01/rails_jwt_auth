require 'rails_helper'

RSpec.describe RailsJwtAuth::Mailer, type: :mailer do
  describe 'confirmation_instructions' do
    let(:user) do
      FactoryBot.create(:active_record_unconfirmed_user,
                         confirmation_token: 'abcd', confirmation_sent_at: Time.current)
    end

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

    context 'when confirmation_url opton is defined with hash url' do
      before do
        RailsJwtAuth.confirmation_url = 'http://www.host.com/#/url?param=value'
      end

      it 'uses this to generate confirmation url' do
        url = "#{RailsJwtAuth.confirmation_url}&confirmation_token=#{user.confirmation_token}"
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
        expect(mail.from).to include(RailsJwtAuth.mailer_sender)
        expect(mail.body).to include(confirmation_url(confirmation_token: user.confirmation_token))
      end
    end
  end

  describe 'reset_password_instructions' do
    let(:user) do
      FactoryBot.create(:active_record_user,
                         reset_password_token: 'abcd', reset_password_sent_at: Time.current)
    end

    let(:mail) { described_class.reset_password_instructions(user).deliver_now }

    it 'sends email with correct info' do
      expect { mail }.to change { ActionMailer::Base.deliveries.count }.by(1)
      expect(mail.subject).to eq(I18n.t('rails_jwt_auth.mailer.reset_password_instructions.subject'))
      expect(mail.to).to include(user.email)
      expect(mail.from).to include(RailsJwtAuth.mailer_sender)
      expect(mail.body).to include(password_url(reset_password_token: user.reset_password_token))
    end

    context 'when reset_password_url opton is defined' do
      before do
        RailsJwtAuth.reset_password_url = 'http://my-url.com'
      end

      it 'uses this to generate reset_password url' do
        url = "#{RailsJwtAuth.reset_password_url}?reset_password_token=#{user.reset_password_token}"
        expect(mail.body).to include(url)
      end
    end

    context 'when reset_password_url opton is defined with hash url' do
      before do
        RailsJwtAuth.reset_password_url = 'http://www.host.com/#/url?param=value'
      end

      it 'uses this to generate confirmation url' do
        url = "#{RailsJwtAuth.reset_password_url}&reset_password_token=#{user.reset_password_token}"
        expect(mail.body).to include(url)
      end
    end
  end

  describe 'set_password_instructions' do
    let(:user) do
      FactoryBot.create(:active_record_user,
                         reset_password_token: 'abcd', reset_password_sent_at: Time.current)
    end

    let(:mail) { described_class.set_password_instructions(user).deliver_now }

    it 'sends email with correct info' do
      expect { mail }.to change { ActionMailer::Base.deliveries.count }.by(1)
      expect(mail.subject).to eq(I18n.t('rails_jwt_auth.mailer.set_password_instructions.subject'))
      expect(mail.to).to include(user.email)
      expect(mail.from).to include(RailsJwtAuth.mailer_sender)
      expect(mail.body).to include(password_url(reset_password_token: user.reset_password_token))
    end

    context 'when set_password_url opton is defined' do
      before do
        RailsJwtAuth.set_password_url = 'http://my-url.com'
      end

      it 'uses this to generate reset_password url' do
        url = "#{RailsJwtAuth.set_password_url}?reset_password_token=#{user.reset_password_token}"
        expect(mail.body).to include(url)
      end
    end

    context 'when set_password_url opton is defined with hash url' do
      before do
        RailsJwtAuth.set_password_url = 'http://www.host.com/#/url?param=value'
      end

      it 'uses this to generate confirmation url' do
        url = "#{RailsJwtAuth.set_password_url}&reset_password_token=#{user.reset_password_token}"
        expect(mail.body).to include(url)
      end
    end
  end

  describe 'send_invitation' do
    let(:user) do
      FactoryBot.create(:active_record_user,
                         invitation_token: 'abcd', invitation_created_at: Time.current)
    end

    let(:mail) { described_class.send_invitation(user).deliver_now }

    it 'sends email with correct info' do
      expect { mail }.to change { ActionMailer::Base.deliveries.count }.by(1)
      expect(mail.subject).to eq(I18n.t('rails_jwt_auth.mailer.send_invitation.subject'))
      expect(mail.to).to include(user.email)
      expect(mail.from).to include(RailsJwtAuth.mailer_sender)
      expect(mail.body).to include(invitations_url(invitation_token: user.invitation_token))
    end

    context 'with accept_invitation_url defined' do
      before do
        RailsJwtAuth.accept_invitation_url = 'http://my-url.com'
      end

      it 'uses this to generate invitation url' do
        url = "#{RailsJwtAuth.accept_invitation_url}?invitation_token=#{user.invitation_token}"
        expect(mail.body).to include(url)
      end
    end

    context 'when accept_invitation_url opton is defined with hash url' do
      before do
        RailsJwtAuth.accept_invitation_url = 'http://www.host.com/#/url?param=value'
      end

      it 'uses this to generate invitation url' do
        url = "#{RailsJwtAuth.accept_invitation_url}&invitation_token=#{user.invitation_token}"
        expect(mail.body).to include(url)
      end
    end
  end
end
