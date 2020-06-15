require 'rails_helper'

describe RailsJwtAuth::Recoverable do
  %w(ActiveRecord Mongoid).each do |orm|
    context "when use #{orm}" do
      before(:all) { RailsJwtAuth.model_name = "#{orm}User" }

      let(:user) { FactoryBot.create("#{orm.underscore}_user") }

      describe '#attributes' do
        it { expect(user).to respond_to(:reset_password_token) }
        it { expect(user).to respond_to(:reset_password_sent_at) }
      end

      describe '#send_reset_password_instructions' do
        it 'fills reset password fields' do
          user.send_reset_password_instructions
          user.reload
          expect(user.reset_password_token).not_to be_nil
          expect(user.reset_password_sent_at).not_to be_nil
        end

        it 'sends reset password email' do
          expect(RailsJwtAuth).to receive(:send_email).with(:reset_password_instructions, user)
          user.send_reset_password_instructions
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
            expect(RailsJwtAuth).not_to receive(:send_email)
              .with(:reset_password_instructions, user)

            user.send_reset_password_instructions
          end
        end

        context 'when user is locked' do
          let(:user) { FactoryBot.create("#{orm.underscore}_user", locked_at: 2.minutes.ago) }

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

        context 'when email field config is invalid' do
          it 'throws InvalidEmailField exception' do
            allow(RailsJwtAuth).to receive(:email_field_name).and_return(:invalid)

            expect {
              user.send_reset_password_instructions
            }.to raise_error(RailsJwtAuth::InvalidEmailField)
          end
        end
      end

      describe '#set_and_send_password_instructions' do
        let(:user) { FactoryBot.build("#{orm.underscore}_user", password: nil) }

        it 'set password and confirm' do
          user.set_and_send_password_instructions
          user.reload
          expect(user.password).not_to be_nil
          expect(user.confirmed_at).not_to be_nil
        end

        it 'fills set password fields' do
          user.set_and_send_password_instructions
          user.reload
          expect(user.reset_password_token).not_to be_nil
          expect(user.reset_password_sent_at).not_to be_nil
        end

        it 'sends set password email' do
          expect(RailsJwtAuth).to receive(:send_email).with(:set_password_instructions, user)
          user.set_and_send_password_instructions
        end
      end

      describe '#before_save' do
        context 'when updates password' do
          it 'cleans reset password token and sessions' do
            user.reset_password_token = 'abcd'
            user.reset_password_sent_at = Time.current
            user.auth_tokens = ['test']
            user.save
            expect(user.reload.reset_password_token).not_to be_nil

            user.password = 'newpassword'
            user.save
            user.reload
            expect(user.reset_password_token).to be_nil
            expect(user.auth_tokens).to be_empty
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
