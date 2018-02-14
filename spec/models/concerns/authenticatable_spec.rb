require 'rails_helper'

describe RailsJwtAuth::Authenticatable do
  %w(ActiveRecord Mongoid).each do |orm|
    let(:user) { FactoryGirl.create("#{orm.underscore}_user") }

    context "when use #{orm}" do
      describe '#attributes' do
        it { expect(user).to have_attributes(email: user.email) }
        it { expect(user).to have_attributes(password: user.password) }
        it { expect(user).to have_attributes(password: user.password) }
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
    end
  end
end
