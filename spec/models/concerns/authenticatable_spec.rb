require 'rails_helper'

describe RailsJwtAuth::Authenticatable do
  %w[ActiveRecord Mongoid].each do |orm|
    let(:user) { FactoryGirl.create("#{orm.underscore}_user", sessions: [{id: 'abcd'}]) }

    context "when use #{orm}" do
      describe '#attributes' do
        it { expect(user).to have_attributes(email: user.email) }
        it { expect(user).to have_attributes(password: user.password) }
        it { expect(user).to have_attributes(sessions: user.sessions) }
      end

      describe '#validators' do
        it 'validates email' do
          user.email = 'invalid'
          user.valid?
          error = I18n.t('rails_jwt_auth.errors.email.invalid')
          expect(user.errors.messages[:email]).to include(error)
        end
      end

      describe '#before_validation' do
        it 'downcases email' do
          user = FactoryGirl.create("#{orm.underscore}_user", email: 'MyEmail@email.com')
          user.valid?
          expect(user.email).to eq('myemail@email.com')
        end
      end

      describe '#authenticate' do
        it 'authenticates user valid password' do
          user = FactoryGirl.create(:active_record_user, password: '12345678')
          expect(user.authenticate('12345678')).not_to eq(false)
          expect(user.authenticate('invalid')).to eq(false)
        end
      end

      describe '#update_with_password' do
        let(:user) { FactoryGirl.create(:active_record_user, password: '12345678') }

        context 'when curren_password is blank' do
          it 'returns false' do
            expect(user.update_with_password(password: 'new_password')).to be_falsey
          end

          it 'addd blank error message' do
            user.update_with_password(password: 'new_password')
            expect(user.errors.messages[:current_password]).to include(
              I18n.t('rails_jwt_auth.errors.current_password.blank')
            )
          end

          it "don't updates password" do
            user.update_with_password(password: 'new_password')
            expect(user.authenticate('new_password')).to be_falsey
          end
        end

        context 'when curren_password is invalid' do
          it 'returns false' do
            expect(user.update_with_password(current_password: 'invalid')).to be_falsey
          end

          it 'addd blank error message' do
            user.update_with_password(current_password: 'invalid')
            expect(user.errors.messages[:current_password]).to include(
              I18n.t('rails_jwt_auth.errors.current_password.invalid')
            )
          end

          it "don't updates password" do
            user.update_with_password(current_password: 'invalid')
            expect(user.authenticate('new_password')).to be_falsey
          end
        end

        context 'when curren_password is valid' do
          it 'returns true' do
            expect(
              user.update_with_password(current_password: '12345678', password: 'new_password')
            ).to be_truthy
          end

          it 'updates password' do
            user.update_with_password(current_password: '12345678', password: 'new_password')
            expect(user.authenticate('new_password')).to be_truthy
          end
        end
      end

      describe '#create_session' do
        context 'when simultaneous_sessions = 1' do
          before do
            RailsJwtAuth.simultaneous_sessions = 1
          end

          it 'creates new session' do
            old_session = user.sessions.first
            expect(user.create_session).not_to be_falsey
            expect(user.reload.sessions.length).to eq(1)
            expect(user.sessions.first[:id]).not_to eq(old_session[:id])
          end

          it 'saves passed info' do
            info = {id: '127.0.0.1'}
            session = user.create_session info
            expect(session[:ip]).to eq(info[:ip])
          end

          it 'saves created_at' do
            session = user.create_session
            expect(session[:created_at]).not_to be_nil
          end
        end

        context 'when simultaneous_sessions = 2' do
          before do
            RailsJwtAuth.simultaneous_sessions = 2
          end

          it 'creates new session and removes those that are outside the limit' do
            old_session = user.sessions.first
            expect(user.create_session).not_to be_falsey
            expect(user.reload.sessions.length).to eq(2)
            expect(user.sessions.first[:id]).to eq(old_session[:id])
            expect(user.sessions.last[:id]).not_to eq(old_session[:id])

            old_session = user.sessions.first
            expect(user.create_session).not_to be_falsey
            expect(user.reload.sessions.length).to eq(2)
            expect(user.sessions.first[:id]).not_to eq(old_session[:id])
          end
        end
      end

      describe '#destroy_session' do
        before do
          RailsJwtAuth.simultaneous_sessions = 2
        end

        it 'destroys specified session from user' do
          session = user.create_session
          expect(user.reload.sessions.length).to eq(2)

          user.destroy_session(session[:id])
          expect(user.reload.sessions.length).to eq(1)
          expect(user.sessions.first[:id]).not_to eq(session[:id])
        end
      end

      describe '.get_by_session_id' do
        it 'returns user with specified session_id' do
          session = user.create_session
          expect(user.class.get_by_session_id(session[:id])).to eq(user)
          expect(user.class.get_by_session_id('invalid')).to eq(nil)
        end
      end
    end
  end
end
