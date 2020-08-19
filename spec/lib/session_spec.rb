require 'rails_helper'

require 'rails_jwt_auth/session'

module RailsJwtAuth
  describe Session do
    %w[ActiveRecord Mongoid].each do |orm|
      context "when use #{orm}" do
        before(:all) { initialize_orm(orm) }

        let(:pass) { '12345678' }
        let(:user) { FactoryBot.create("#{orm.underscore}_user", password: pass) }
        let(:unconfirmed_user) {
          FactoryBot.create("#{orm.underscore}_unconfirmed_user", password: pass)
        }

        describe '#initialize' do
          it 'does not fail when pass empty hash' do
            allow(RailsJwtAuth).to receive(:downcase_auth_field).and_return(true)
            expect { Session.new }.not_to raise_exception
          end

          it 'downcase auth_field when options is enabled' do
            session = Session.new('email' => 'AAA@email.com', password: pass)
            expect(session.instance_variable_get(:@auth_field_value)).to eq('AAA@email.com')

            allow(RailsJwtAuth).to receive(:downcase_auth_field).and_return(true)
            session = Session.new('email' => 'AAA@email.com', password: pass)
            expect(session.instance_variable_get(:@auth_field_value)).to eq('aaa@email.com')
          end
        end

        describe '#valid?' do
          it 'returns true when session is valid' do
            session = Session.new('email' => user.email, password: pass)
            expect(session.valid?).to be_truthy
          end

          it 'returns false when session is invalid' do
            session = Session.new('email' => user.email, password: 'invalid')
            expect(session.valid?).to be_falsey
          end

          it 'validates auth field and password presence' do
            session = Session.new
            expect(session.valid?).to be_falsey
            expect(get_record_error(session, :email)).to eq(:blank)
            expect(get_record_error(session, :password)).to eq(:blank)
          end

          it 'validates auth field' do
            session = Session.new('email' => 'invalid')
            expect(session.valid?).to be_falsey
            expect(get_record_error(session, :session)).to eq(:invalid)

            RailsJwtAuth.avoid_email_errors = false
            session = Session.new('email' => 'invalid')
            expect(session.valid?).to be_falsey
            expect(get_record_error(session, :email)).to eq(:invalid)
          end

          it 'validates password' do
            session = Session.new('email' => user.email, password: 'invalid')
            expect(session.valid?).to be_falsey
            expect(get_record_error(session, :session)).to eq(:invalid)

            RailsJwtAuth.avoid_email_errors = false
            session = Session.new('email' => user.email, password: 'invalid')
            expect(session.valid?).to be_falsey
            expect(get_record_error(session, :password)).to eq(:invalid)
          end

          it 'validates user is valid' do
            session = Session.new('email' => user.email, password: pass)
            allow(session.user).to receive(:save).and_return(false)
            expect(session.generate!(nil)).to be_falsey
            expect(get_record_error(session, "#{orm.underscore}_user".to_sym)).to eq(:invalid)
          end

          it 'validates user is unconfirmed' do
            session = Session.new('email' => unconfirmed_user.email, password: 'invalid')
            expect(session.valid?).to be_falsey
            expect(get_record_error(session, :email)).to eq(:unconfirmed)
          end

          it 'validates user is not locked' do
            user.lock_access
            session = Session.new('email' => user.email, password: 'invalid')
            expect(session.valid?).to be_falsey
            expect(get_record_error(session, :email)).to eq(:locked)
          end

          it 'avoid validates password when exist other errors' do
            session = Session.new('email' => unconfirmed_user.email, password: 'invalid')
            expect(session.valid?).to be_falsey
            expect(get_record_error(session, :password)).to be_nil
          end
        end

        describe '#generate!' do
          it 'increase failed attemps' do
            Session.new('email' => user.email, password: 'invalid').generate!(nil)
            expect(user.reload.failed_attempts).to eq(1)
          end

          it 'unlock access when lock is expired' do
            travel_to(Date.today - 30.days) { user.lock_access }
            session = Session.new('email' => user.email, password: pass)
            expect(session.generate!(nil)).to be_truthy
            expect(user.reload.locked_at).to be_nil
          end

          it 'resets recovery password' do
            travel_to(Date.today - 30.days) { user.send_reset_password_instructions }
            session = Session.new('email' => user.email, password: pass)
            expect(session.generate!(nil)).to be_truthy
            expect(user.reload.reset_password_token).to be_nil
            expect(user.reload.reset_password_sent_at).to be_nil
          end

          it 'track session' do
            freeze_time
            request = OpenStruct.new(ip: '127.0.0.1')
            session = Session.new('email' => user.email, password: pass)
            expect(session.generate!(request)).to be_truthy
            expect(user.reload.last_sign_in_at).to eq(Time.current)
            expect(user.reload.last_sign_in_ip).to eq('127.0.0.1')
          end
        end
      end
    end
  end
end
