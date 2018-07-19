require 'rails_helper'

describe RailsJwtAuth::Recoverable do
  %w(ActiveRecord Mongoid).each do |orm|
    let(:user) { FactoryBot.create("#{orm.underscore}_user") }

    before :all do
      class Mock
        def deliver
        end

        def deliver_later
        end
      end
    end

    context "when use #{orm}" do
      describe '#attributes' do
        it { expect(user).to respond_to(:reset_password_token) }
        it { expect(user).to respond_to(:reset_password_sent_at) }
      end

      describe '#send_reset_password_instructions' do
        it 'fills reset password fields' do
          mock = Mock.new
          allow(RailsJwtAuth::Mailer).to receive(:reset_password_instructions).and_return(mock)
          user.send_reset_password_instructions
          user.reload
          expect(user.reset_password_token).not_to be_nil
          expect(user.reset_password_sent_at).not_to be_nil
        end

        it 'sends reset password email' do
          mock = Mock.new
          allow(RailsJwtAuth::Mailer).to receive(:reset_password_instructions).and_return(mock)
          expect(mock).to receive(:deliver)
          user.send_reset_password_instructions
        end

        context 'when use deliver_later option' do
          before { RailsJwtAuth.deliver_later = true }
          after  { RailsJwtAuth.deliver_later = false }

          it 'uses deliver_later method to send email' do
            mock = Mock.new
            allow(RailsJwtAuth::Mailer).to receive(:reset_password_instructions).and_return(mock)
            expect(mock).to receive(:deliver_later)
            user.send_reset_password_instructions
          end
        end

        context 'when user is unconfirmed' do
          let(:user) { FactoryBot.create("#{orm.underscore}_unconfirmed_user") }

          it 'returns false' do
            expect(user.send_reset_password_instructions).to be_falsey
          end

          it 'does not fill reset password fields' do
            user.send_reset_password_instructions
            user.reload
            expect(user.reset_password_token).to be_nil
            expect(user.reset_password_sent_at).to be_nil
          end

          it 'doe not send reset password email' do
            expect(RailsJwtAuth::Mailer).not_to receive(:reset_password_instructions)
            user.send_reset_password_instructions
          end
        end
      end

      describe '#set_and_send_password_instructions' do
        let(:user) { FactoryBot.build("#{orm.underscore}_user", password: nil) }

        it 'set password and confirm' do
          mock = Mock.new
          allow(RailsJwtAuth::Mailer).to receive(:reset_password_instructions).and_return(mock)
          user.set_and_send_password_instructions
          user.reload
          expect(user.password).not_to be_nil
          expect(user.confirmed_at).not_to be_nil
        end

        it 'fills set password fields' do
          mock = Mock.new
          allow(RailsJwtAuth::Mailer).to receive(:reset_password_instructions).and_return(mock)
          user.set_and_send_password_instructions
          user.reload
          expect(user.reset_password_token).not_to be_nil
          expect(user.reset_password_sent_at).not_to be_nil
        end

        it 'sends set password email' do
          mock = Mock.new
          allow(RailsJwtAuth::Mailer).to receive(:set_password_instructions).and_return(mock)
          expect(mock).to receive(:deliver)
          user.set_and_send_password_instructions
        end

        context 'when use deliver_later option' do
          before { RailsJwtAuth.deliver_later = true }
          after  { RailsJwtAuth.deliver_later = false }

          it 'uses deliver_later method to send email' do
            mock = Mock.new
            allow(RailsJwtAuth::Mailer).to receive(:set_password_instructions).and_return(mock)
            expect(mock).to receive(:deliver_later)
            user.set_and_send_password_instructions
          end
        end
      end

      describe '#before_save' do
        context 'when updates password' do
          it 'cleans reset password token' do
            user.reset_password_token = 'abcd'
            user.reset_password_sent_at = Time.current
            user.save
            expect(user.reload.reset_password_token).not_to be_nil

            user.password = 'newpassword'
            user.save
            expect(user.reload.reset_password_token).to be_nil
          end
        end
      end

      describe '#validations' do
        context 'when reset password token has expired' do
          before do
            RailsJwtAuth.reset_password_expiration_time = 1.second
          end

          after do
            RailsJwtAuth.reset_password_expiration_time = 1.day
          end

          it 'adds expiration error' do
            user.reset_password_token = 'abcd'
            user.reset_password_sent_at = Time.current
            user.save
            sleep 1

            user.password = 'newpassword'
            expect(user.save).to be_falsey
            expect(user.errors.details[:reset_password_token].first[:error]).to eq :expired
          end
        end
      end
    end
  end
end
