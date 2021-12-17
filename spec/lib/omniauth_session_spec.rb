require 'rails_helper'

require 'rails_jwt_auth/omniauth_session'

module RailsJwtAuth
  describe OmniauthSession do
    %w[ActiveRecord Mongoid].each do |orm|
      context "when use #{orm}" do
        before(:all) { initialize_orm(orm) }

        let(:pass) { '12345678' }
        let(:user) { FactoryBot.create("#{orm.underscore}_user", password: pass) }
        let(:unconfirmed_user) {
          FactoryBot.create("#{orm.underscore}_unconfirmed_user", password: pass)
        }

        describe '#initialize' do
          it 'does not fail when pass empty user' do
            expect { OmniauthSession.new(nil) }.not_to raise_exception
          end
        end

        describe '#valid?' do
          it 'returns true when user is valid' do
            session = OmniauthSession.new(user)
            expect(session.valid?).to be_truthy
          end

          it 'returns false when user is invalid' do
            session = OmniauthSession.new(nil)
            expect(session.valid?).to be_falsey
          end

          it 'validates user' do
            session = OmniauthSession.new(nil)
            expect(session.valid?).to be_falsey
            expect(get_record_error(session, :session)).to eq(:not_found)
          end

          it 'validates user is unconfirmed' do
            session = OmniauthSession.new(unconfirmed_user)
            expect(session.valid?).to be_falsey
            expect(get_record_error(session, :email)).to eq(:unconfirmed)
          end

          it 'validates user is not locked' do
            user.lock_access
            session = OmniauthSession.new user
            expect(session.valid?).to be_falsey
            expect(get_record_error(session, :email)).to eq(:locked)
          end
        end

        describe '#generate!' do
          it 'increase failed attemps' do
            allow_any_instance_of(RailsJwtAuth::OmniauthSession).to(
              receive(:valid?).and_return(false)
            )
            OmniauthSession.new(user).generate!
            expect(user.reload.failed_attempts).to eq(1)
          end

          it 'unlock access when lock is expired' do
            travel_to(Date.today - 30.days) { user.lock_access }
            session = OmniauthSession.new(user)
            expect(session.generate!).to be_truthy
            expect(user.reload.locked_at).to be_nil
          end

          it 'resets recovery password' do
            travel_to(Date.today - 30.days) { user.send_reset_password_instructions }
            session = OmniauthSession.new user
            expect(session.generate!).to be_truthy
            expect(user.reload.reset_password_token).to be_nil
            expect(user.reload.reset_password_sent_at).to be_nil
          end
        end
      end
    end
  end
end
