require 'rails_helper'

describe RailsJwtAuth::Confirmable do
  %w[ActiveRecord Mongoid].each do |orm|
    context "when use #{orm}" do
      before(:all) { RailsJwtAuth.model_name = "#{orm}User" }

      let(:user) { FactoryBot.create("#{orm.underscore}_user") }
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

      describe '#confirm!' do
        it 'confirms user' do
          unconfirmed_user.confirm!
          expect(unconfirmed_user.confirmed?).to be_truthy
        end

        context 'when unconfirmed_email exists' do
          it 'confirms new email' do
            user.email = 'new@email.com'
            user.save

            user.confirm!
            expect(user.reload.email).to eq('new@email.com')
            expect(user.confirmed?).to be_truthy
          end
        end

        context 'when new_email confirmation token has expired' do
          it 'adds expiration error' do
            user.email = 'new@email.com'
            user.save

            Timecop.freeze(Date.today + 30) do
              expect(user.confirm!).to be_falsey
              expect(user.errors.details[:confirmation_token].first[:error]).to eq :expired
            end
          end
        end

        context 'when user has email confirmation field' do
          it 'fill in with email' do
            user.email = 'new@email.com'
            user.save

            user.confirm!
            expect(user.email_confirmation).to eq(user.email)
          end
        end
      end

      describe '#skip_confirmation!' do
        it 'skips user confirmation after create' do
          new_user = FactoryBot.build("#{orm.underscore}_user")
          new_user.skip_confirmation!
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
          expect(RailsJwtAuth).to receive(:send_email).with(:confirmation_instructions, anything)
          new_user.send_confirmation_instructions
        end

        context 'when user is confirmed' do
          it 'returns false' do
            expect(user.send_confirmation_instructions).to eq(false)
          end

          it 'addds error to user' do
            user.send_confirmation_instructions
            expect(user.errors.details[:email].first[:error]).to eq :already_confirmed
          end

          it 'does not send confirmation email' do
            expect(RailsJwtAuth).not_to receive(:send_email)
              .with(:confirmation_instructions, anything)

            user.send_confirmation_instructions
          end

          context 'when user has unconfirmed_email' do
            it 'return true' do
              user.email = 'new@email.com'
              user.save
              expect(user.unconfirmed_email).to eq('new@email.com')
              expect(user.send_confirmation_instructions).to eq(true)
            end
          end
        end

        context 'when email field config is invalid' do
          it 'throws InvalidEmailField exception' do
            allow(RailsJwtAuth).to receive(:email_field_name).and_return(:invalid)

            expect do
              user.send_confirmation_instructions
            end.to raise_error(RailsJwtAuth::InvalidEmailField)
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

      describe '#before_update' do
        context 'when email is updated' do
          before do
            ActionMailer::Base.deliveries.clear
          end

          it 'fills in unconfirmed_email field' do
            old_email = user.email
            user.email = 'new@email.com'
            user.save
            user.reload
            expect(user.unconfirmed_email).to eq('new@email.com')
            expect(user.email).to eq(old_email)
          end

          context 'when send_email_changed_notification option is false' do
            before do
              allow(RailsJwtAuth).to receive(:send_email_changed_notification).and_return(false)
            end

            it 'sends only confirmation email' do
              expect(RailsJwtAuth).to receive(:send_email).with(:confirmation_instructions, user)
              expect(RailsJwtAuth).not_to receive(:send_email).with(:email_changed, user)
              user.update(email: 'new@email.com')
            end

            it 'adds correct confirmation token to email' do # check bug, don't delete
              user.update(email: 'new@email.com')
              first_token = user.confirmation_token
              expect(first_token).not_to be_nil
              mail = ActionMailer::Base.deliveries.last
              expect(mail.subject).to eq('Confirmation instructions')
              expect(mail.body).to match("token=#{first_token}")

              user.update(email: 'new2@email.com')
              second_token = user.confirmation_token
              expect(second_token).not_to be_nil
              expect(second_token) != first_token
              mail = ActionMailer::Base.deliveries.last
              expect(mail.subject).to eq('Confirmation instructions')
              expect(mail.body).to match("token=#{second_token}")
            end
          end

          context 'when send_email_changed_notification option is true' do
            it 'sends confirmation and nofication email' do
              allow(RailsJwtAuth).to receive(:send_email_changed_notification).and_return(true)
              expect(RailsJwtAuth).to receive(:send_email).with(:email_changed, user)
              expect(RailsJwtAuth).to receive(:send_email).with(:confirmation_instructions, user)
              old_email = user.email
              user.update(email: 'new@email.com')
            end
          end
        end
      end

      describe '#validations' do
        context 'when confirmation token has expired' do
          context 'try to confirm user' do
            it 'adds expiration error' do
              unconfirmed_user.confirmed_at = Time.current

              Timecop.freeze(Date.today + 30) do
                expect(unconfirmed_user.save).to be_falsey
                expect(unconfirmed_user.errors.details[:confirmation_token].first[:error]).to eq(
                  :expired
                )
              end
            end
          end
        end
      end
    end
  end
end
