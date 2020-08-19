require 'rails_helper'

describe RailsJwtAuth::Authenticatable do
  %w[ActiveRecord Mongoid].each do |orm|
    context "when use #{orm}" do
      before(:all) { initialize_orm(orm) }

      let(:user) { FactoryBot.create("#{orm.underscore}_user", auth_tokens: %w[abcd]) }

      describe '#attributes' do
        it { expect(user).to have_attributes(password: user.password) }
        it { expect(user).to have_attributes(auth_tokens: user.auth_tokens) }
      end

      describe '#before_validation' do
        it 'downcase auth field when downcase_auth_field options is actived' do
          user = FactoryBot.create("#{orm.underscore}_user", email: 'AAA@email.com')
          expect(user.reload.email).to eq('AAA@email.com')

          allow(RailsJwtAuth).to receive(:downcase_auth_field).and_return(true)
          user = FactoryBot.create("#{orm.underscore}_user", email: 'BBB@email.com')
          expect(user.reload.email).to eq('bbb@email.com')
        end

        it 'does not fail when auth field is blank and apply downcase!' do
          allow(RailsJwtAuth).to receive(:downcase_auth_field).and_return(true)
          user = FactoryBot.create("#{orm.underscore}_user", email: 'BBB@email.com')
          user.email = nil
          expect { user.valid? }.not_to raise_exception
        end
      end

      describe '#authenticate' do
        it 'authenticates user valid password' do
          user = FactoryBot.create("#{orm.underscore}_user", password: '12345678')
          expect(user.authenticate('12345678')).not_to eq(false)
          expect(user.authenticate('invalid')).to eq(false)
        end
      end

      describe '#update_password' do
        let(:current_password) { '12345678' }
        let(:user) { FactoryBot.create("#{orm.underscore}_user", password: current_password) }
        let(:new_password) { 'new_password' }
        let(:new_password_params) { {current_password: current_password, password: new_password} }

        context 'when curren_password is blank' do
          it 'returns false' do
            expect(user.update_password(password: 'new_password')).to be_falsey
          end

          it 'addd blank error message' do
            user.update_password(password: 'new_password')
            expect(user.errors.messages[:current_password].first).to eq 'blank'
          end

          it 'validates other fields' do
            user.update_password(password: 'new_password', email: '')
            expect(user.errors.messages[:email].first).not_to be 'nil'
          end

          it "don't updates password" do
            user.update_password(password: 'new_password')
            expect(user.reload.authenticate('new_password')).to be_falsey
          end
        end

        context 'when curren_password is invalid' do
          it 'returns false' do
            expect(user.update_password(current_password: 'invalid')).to be_falsey
          end

          it 'addd blank error message' do
            user.update_password(current_password: 'invalid')
            expect(user.errors.messages[:current_password].first).to eq 'invalid'
          end

          it "don't updates password" do
            user.update_password(current_password: 'invalid')
            expect(user.authenticate('new_password')).to be_falsey
          end
        end

        context 'when curren_password is valid' do
          it 'returns true' do
            expect(
              user.update_password(current_password: '12345678', password: 'new_password')
            ).to be_truthy
          end

          it 'updates password' do
            user.update_password(current_password: '12345678', password: 'new_password')
            expect(user.authenticate('new_password')).to be_truthy
          end

          it 'clean sessions' do
            user.update_password(current_password: '12345678', password: 'new_password')
            expect(user.auth_tokens).to be_empty

            user.update_password(
              current_password: '12345678',
              password: 'new_password',
              current_auth_token: 'xxx'
            )
            expect(user.auth_tokens).to eq(['xxx'])
          end
        end

        context 'when password is blank' do
          it 'addd blank error message' do
            user.update_password(password: '')
            expect(user.errors.messages[:password].first).to eq 'blank'
          end
        end

        context 'when send_password_changed_notification option is false' do
          it 'does not send notify email' do
            allow(RailsJwtAuth).to receive(:send_password_changed_notification).and_return(false)
            expect(RailsJwtAuth).not_to receive(:send_email)
              .with(:password_changed_notification, user)
            user.update_password(new_password_params)
          end
        end

        context 'when send_password_changed_notification option is true' do
          it 'sends confirmation and nofication email' do
            expect(RailsJwtAuth).to receive(:send_email).with(:password_changed_notification, user)
            user.update_password(new_password_params)
          end
        end

        context 'when RailsJwtAuth::Authenticable is used with RailsJwtAuth::Recoverable' do
          context 'when reset_password_sent_at is expired' do
            before do
              @user = FactoryBot.create("#{orm.underscore}_user",
                                        password: current_password,
                                        reset_password_token: 'xxx',
                                        reset_password_sent_at: Time.current)

              travel(RailsJwtAuth.reset_password_expiration_time)
            end

            after do
              travel_back
            end

            it 'reset recoverable fields' do
              @user.update_password(new_password_params)
              @user.reload
              expect(@user.reset_password_sent_at).to be_nil
              expect(@user.reset_password_token).to be_nil
            end

            it 'updates password' do
              expect(@user.update_password(new_password_params)).to be_truthy
              expect(@user.reload.authenticate(new_password)).to be_truthy
            end
          end

          context 'when reset_password_sent_at is valid' do
            before do
              @user = FactoryBot.create("#{orm.underscore}_user",
                                        password: current_password,
                                        reset_password_token: 'xxxx',
                                        reset_password_sent_at: Time.current)
            end

            it 'reset recoverable fields' do
              @user.update_password(new_password_params)
              @user.reload
              expect(@user.reset_password_sent_at).to be_nil
              expect(@user.reset_password_token).to be_nil
            end

            it 'updates password' do
              expect(@user.update_password(new_password_params)).to be_truthy
              expect(@user.reload.authenticate(new_password)).to be_truthy
            end
          end
        end
      end

      describe '#regenerate_auth_token' do
        context 'when simultaneous_sessions = 1' do
          before do
            RailsJwtAuth.simultaneous_sessions = 1
          end

          it 'creates new authentication token' do
            old_token = user.auth_tokens.first
            user.regenerate_auth_token
            expect(user.auth_tokens.length).to eq(1)
            expect(user.auth_tokens.first).not_to eq(old_token)
          end
        end

        context 'when simultaneous_sessions = 2' do
          before do
            RailsJwtAuth.simultaneous_sessions = 2
          end

          context 'when don\'t pass token' do
            it 'creates new authentication token' do
              old_token = user.auth_tokens.first
              user.regenerate_auth_token
              expect(user.auth_tokens.length).to eq(2)
              expect(user.auth_tokens.first).to eq(old_token)

              new_old_token = user.auth_tokens.last
              user.regenerate_auth_token
              expect(user.auth_tokens.length).to eq(2)
              expect(user.auth_tokens).not_to include(old_token)
              expect(user.auth_tokens.first).to eq(new_old_token)
            end
          end

          context 'when pass token' do
            it 'regeneates this token' do
              old_token = user.auth_tokens.first
              user.regenerate_auth_token old_token
              expect(user.auth_tokens.length).to eq(1)
              expect(user.auth_tokens.first).not_to eq(old_token)
            end
          end
        end
      end

      describe '#destroy_auth_token' do
        before do
          RailsJwtAuth.simultaneous_sessions = 2
        end

        it 'destroy specified token from user auth tokens array' do
          user.regenerate_auth_token
          expect(user.auth_tokens.length).to eq(2)

          token = user.auth_tokens.first
          user.destroy_auth_token token
          expect(user.auth_tokens.length).to eq(1)
          expect(user.auth_tokens.first).not_to eq(token)
        end
      end

      describe '#to_token_payload' do
        context 'when use simultaneous sessions' do
          it 'returns payload with auth_token' do
            payload = user.to_token_payload
            expect(payload[:auth_token]).to eq(user.auth_tokens.first)
          end
        end

        context 'when simultaneous sessions are 0' do
          it 'returns payload with user id' do
            allow(RailsJwtAuth).to receive(:simultaneous_sessions).and_return(0)
            payload = user.to_token_payload
            expect(payload[:auth_token]).to be_nil
            expect(payload[:id]).to eq(user.id.to_s)
          end
        end
      end

      describe '#save_without_password' do
        it 'avoid password validation' do
          u = FactoryBot.build("#{orm.underscore}_user_without_password")
          expect(u.save).to be_falsey
          expect(u.save_without_password).to be_truthy
        end

        it 'remove password  and password_confirmation before save' do
          u = FactoryBot.build(
            "#{orm.underscore}_user",
            password: 'invalid',
            password_confirmation: 'invalid_confirmation'
          )

          expect(u.save_without_password).to be_truthy
          expect(u.password).to be_nil
          expect(u.password_confirmation).to be_nil
          expect(u.reload.password_digest).to be_nil
        end
      end

      describe '#valid_without_password?' do
        it 'avoid validates password' do
          u = FactoryBot.build("#{orm.underscore}_user_without_password")
          expect(u.valid?).to be_falsey
          expect(u.valid_without_password?).to be_truthy
        end
      end

      describe '.from_token_payload' do
        context 'when use simultaneous sessions' do
          it 'returns user by auth token' do
            user.regenerate_auth_token

            expect(
              RailsJwtAuth.model.from_token_payload({'auth_token' => user.auth_tokens.last})
            ).to eq(user)
          end
        end

        context 'when simultaneous sessions are 0' do
          it 'returns user by id' do
            allow(RailsJwtAuth).to receive(:simultaneous_sessions).and_return(0)
            expect(RailsJwtAuth.model.from_token_payload({'id' => user.id.to_s})).to eq(user)
          end
        end
      end

      describe '.get_by_token' do
        it 'returns user with specified token' do
          user = FactoryBot.create("#{orm.underscore}_user", auth_tokens: %w[abcd efgh])
          expect(user.class.get_by_token('aaaa')).to eq(nil)
          expect(user.class.get_by_token('abcd')).to eq(user)
        end
      end
    end
  end
end
