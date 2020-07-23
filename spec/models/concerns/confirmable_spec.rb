require 'rails_helper'

describe RailsJwtAuth::Confirmable do
  %w[ActiveRecord Mongoid].each do |orm|
    context "when use #{orm}" do
      before(:all) { initialize_orm(orm) }

      let(:password) { '12345678' }
      let(:user) { FactoryBot.create("#{orm.underscore}_user", password: password) }
      let(:unconfirmed_user) { FactoryBot.create("#{orm.underscore}_unconfirmed_user") }

      describe '#attributes' do
        it { expect(user).to have_attributes(confirmation_token: user.confirmation_token) }
        it { expect(user).to have_attributes(confirmation_sent_at: user.confirmation_sent_at) }
        it { expect(user).to have_attributes(confirmed_at: user.confirmed_at) }
      end

      describe '#confirmed?' do
        it 'returns if user is confirmed' do
          expect(user.confirmed?).to be_truthy
          expect(unconfirmed_user.confirmed?).to be_falsey
        end
      end

      describe '#confirm' do
        it 'confirms user' do
          unconfirmed_user.confirm
          expect(unconfirmed_user.confirmed?).to be_truthy
        end

        context 'when unconfirmed_email exists' do
          it 'confirms new email' do
            user.update_email(email: 'new@email.com', password: password)

            user.confirm
            expect(user.reload.email).to eq('new@email.com')
            expect(user.confirmed?).to be_truthy
          end
        end

        context 'when new_email confirmation token has expired' do
          it 'adds expiration error' do
            user.update_email(email: 'new@email.com', password: password)

            travel_to(Time.current + RailsJwtAuth.confirmation_expiration_time + 1.second) do
              expect(user.confirm).to be_falsey
              expect(get_record_error(user, :confirmation_token)).to eq :expired
            end
          end
        end

        context 'when user has email confirmation field' do
          it 'fill in with email' do
            user.update_email(email: 'new@email.com', password: password)

            user.confirm
            expect(user.email_confirmation).to eq(user.email)
          end
        end
      end

      describe '#skip_confirmation' do
        it 'skips user confirmation after create' do
          new_user = FactoryBot.build("#{orm.underscore}_user")
          new_user.skip_confirmation
          new_user.save
          expect(new_user.confirmed?).to be_truthy
        end
      end

      describe '#send_confirmation_instructions' do
        it 'fills confirmation fields' do
          unconfirmed_user.send_confirmation_instructions
          expect(unconfirmed_user.confirmation_token).not_to be_nil
          expect(unconfirmed_user.confirmation_sent_at).not_to be_nil
        end

        it 'sends confirmation email' do
          new_user = FactoryBot.build("#{orm.underscore}_unconfirmed_user")
          expect(RailsJwtAuth).to receive(:send_email).with(:confirmation_instructions, new_user)
          new_user.send_confirmation_instructions
        end

        context 'when user is confirmed' do
          it 'returns false' do
            expect(user.send_confirmation_instructions).to eq(false)
          end

          it 'addds error to user' do
            user.send_confirmation_instructions
            expect(get_record_error(user, :email)).to eq :already_confirmed
          end

          it 'does not send confirmation email' do
            expect(RailsJwtAuth).not_to receive(:send_email).with(:confirmation_instructions, user)
            user.send_confirmation_instructions
          end

          context 'when user has unconfirmed_email' do
            it 'return true' do
              user.update_email(email: 'new@email.com', password: password)
              expect(user.unconfirmed_email).to eq('new@email.com')
              expect(user.send_confirmation_instructions).to eq(true)
            end
          end
        end
      end

      describe '#update_email' do
        it 'fills in unconfirmed_email and token fields' do
          old_email = user.email
          expect(user.update_email(email: 'new@email.com', password: password)).to be_truthy
          expect(user.reload.unconfirmed_email).to eq('new@email.com')
          expect(user.email).to eq(old_email)
          expect(user.confirmation_token).not_to be_nil
          expect(user.confirmation_sent_at).not_to be_nil
        end

        it 'checks email' do
          expect(user.update_email(email: '')).to be_falsey
          expect(get_record_error(user, :email)).to eq(:blank)

          expect(user.update_email(email: 'invalid')).to be_falsey
          expect(get_record_error(user, :email)).to eq(:invalid)
        end

        it 'checks password' do
          expect(user.update_email(email: 'new@email.com')).to be_falsey
          expect(get_record_error(user, :password)).to eq(:blank)

          expect(user.update_email(email: 'new@email.com', password: :invalid)).to be_falsey
          expect(get_record_error(user, :password)).to eq(:invalid)
        end

        it 'checks that email has changed' do
          expect(user.update_email(email: user.email)).to be_falsey
          expect(get_record_error(user, :email)).to eq(:not_change)
        end

        context 'when send_email_change_requested_notification option is false' do
          it 'sends only confirmation email' do
            allow(RailsJwtAuth).to receive(:send_email_change_requested_notification).and_return(false)
            expect(RailsJwtAuth).to receive(:send_email).with(:confirmation_instructions, user)
            expect(RailsJwtAuth).not_to receive(:send_email).with(:email_change_requested_notification, user)
            user.update_email(email: 'new@email.com', password: password)
          end
        end

        context 'when send_email_change_requested_notification option is true' do
          it 'sends confirmation and nofication email' do
            allow(RailsJwtAuth).to receive(:send_email_change_requested_notification).and_return(true)
            expect(RailsJwtAuth).to receive(:send_email).with(:confirmation_instructions, user)
            expect(RailsJwtAuth).to receive(:send_email).with(:email_change_requested_notification, user)
            user.update_email(email: 'new@email.com', password: password)
          end
        end
      end

      describe '#after_create' do
        it 'sends confirmation instructions' do
          new_user = FactoryBot.build("#{orm.underscore}_user")
          expect(new_user).to receive(:send_confirmation_instructions)
          new_user.save
        end
      end
    end
  end
end
