require 'rails_helper'

describe RailsJwtAuth::Recoverable do
  %w(ActiveRecord Mongoid).each do |orm|
    context "when use #{orm}" do
      before(:all) { initialize_orm(orm) }

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
            expect(RailsJwtAuth).not_to receive(:send_email)
              .with(:reset_password_instructions, user)
            user.send_reset_password_instructions
          end
        end
      end

      describe '#set_reset_password' do
        it 'validates password presence' do
          expect(user.set_reset_password({})).to be_falsey
          expect(get_record_error(user, :password)).to eq(:blank)
        end

        it 'validates reset_password_token' do
          allow(user).to receive(:expired_reset_password_token?).and_return(true)
          expect(user.set_reset_password({})).to be_falsey
          expect(get_record_error(user, :reset_password_token)).to eq(:expired)
        end

        it 'cleans reset password token and sessions' do
          user.reset_password_token = 'abcd'
          user.reset_password_sent_at = Time.current
          user.auth_tokens = ['test']
          user.save

          user.set_reset_password(password: 'newpassword')
          user.reload

          expect(user.reset_password_token).to be_nil
          expect(user.auth_tokens).to be_empty
        end
      end

      describe '#expired_reset_password_token?' do
        context 'when reset password token has expired' do
          it 'returns true' do
            user.reset_password_token = 'abcd'
            user.reset_password_sent_at = Time.current
            user.save

            travel_to(Time.current + RailsJwtAuth.reset_password_expiration_time + 1.second) do
              expect(user.expired_reset_password_token?).to be_truthy
            end
          end
        end
      end
    end
  end
end
