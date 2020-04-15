require 'rails_helper'

require 'rails_jwt_auth/session'

module RailsJwtAuth
  %w[ActiveRecord].each do |orm|
    describe Session do
      before(:all) { initialize_orm(orm) }

      let(:pass) { '12345678' }
      let(:user) { FactoryBot.create("#{orm.underscore}_user", password: pass) }
      let(:unconfirmed_user) {
        FactoryBot.create("#{orm.underscore}_unconfirmed_user", password: pass)
      }

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
          expect(get_record_error(session, :email)).to eq(:invalid)
        end

        it 'validates password' do
          session = Session.new('email' => user.email, password: 'invalid')
          expect(session.valid?).to be_falsey
          expect(get_record_error(session, :password)).to eq(:invalid)
        end

        it 'validates user is unconfirmed' do
          session = Session.new('email' => unconfirmed_user.email, password: 'invalid')
          expect(session.valid?).to be_falsey
          expect(get_record_error(session, :email)).to eq(:unconfirmed)
        end

        it 'validates user is not locked' do
          user.lock_access!
          session = Session.new('email' => user.email, password: 'invalid')
          expect(session.valid?).to be_falsey
          expect(get_record_error(session, :email)).to eq(:locked)
        end
      end

      describe '#generate!' do
        it 'increase failed attemps' do
          Session.new('email' => user.email, password: 'invalid').generate!(nil)
          expect(user.reload.failed_attempts).to eq(1)
        end

        it 'unlock access when lock is expired' do
          travel_to(Date.today - 30.days) { user.lock_access! }
          session = Session.new('email' => user.email, password: pass)
          expect(session.generate!(nil)).to be_truthy
          expect(user.reload.locked_at).to be_nil
        end
      end
    end
  end
end
