require 'rails_helper'

describe RailsJwtAuth::PasswordsController do
  %w(ActiveRecord Mongoid).each do |orm|
    context "when use #{orm}" do
      before :all do
        RailsJwtAuth.model_name = "#{orm}User"
      end

      let(:json) { JSON.parse(response.body) }
      let(:user) { FactoryGirl.create("#{orm.underscore}_user", password: '12345678') }

      describe 'POST #create' do
        context 'when sends valid email' do
          it 'returns 201 http status code' do
            post :create, params: {password: {email: user.email}}
            expect(response).to have_http_status(204)
          end

          it 'sends new reset_password email with new token' do
            class Mock
              def deliver
              end
            end

            expect(RailsJwtAuth::Mailer).to receive(:reset_password_instructions)
              .with(user).and_return(Mock.new)

            old_token = user.reset_password_token
            post :create, params: {password: {email: user.email}}
            expect(user.reload.reset_password_token).not_to eq(old_token)
          end
        end

        context 'when send invalid email' do
          before do
            post :create, params: {password: {email: 'invalid'}}
          end

          it 'returns 422 http status code' do
            expect(response).to have_http_status(422)
          end

          it 'returns not found error' do
            expect(json['errors']['email']).to include(I18n.t('rails_jwt_auth.errors.not_found'))
          end
        end
      end

      describe 'PUT #update' do
        context 'when send all params correctly' do
          before do
            user.send_reset_password_instructions
            put :update, params: {
              reset_password_token: user.reset_password_token,
              password: {password: 'new_password'}
            }
          end

          it 'returns 204 http status code' do
            expect(response).to have_http_status 204
          end

          it 'updates password' do
            expect(user.reload.authenticate('new_password')).to be_truthy
          end
        end

        context 'when reset_password_token is invalid' do
          before do
            put :update, params: {reset_password_token: 'invalid'}
          end

          it 'returns 422 http status code' do
            expect(response).to have_http_status 422
          end

          it 'returns error message' do
            expect(json['errors']['reset_password_token']).to(
              include(I18n.t('rails_jwt_auth.errors.not_found'))
            )
          end
        end

        context 'when does not send reset_password_token' do
          before do
            put :update
          end

          it 'returns 422 http status code' do
            expect(response).to have_http_status 422
          end

          it 'returns error message' do
            expect(json['errors']['reset_password_token']).to(
              include(I18n.t('rails_jwt_auth.errors.not_found'))
            )
          end
        end

        context 'when password confirmation is invalid' do
          before do
            user.send_reset_password_instructions
            put :update, params: {
              reset_password_token: user.reset_password_token,
              password: {password: 'a', password_confirmation: 'b'}
            }
          end

          it 'returns 422 http status code' do
            expect(response).to have_http_status(422)
          end

          it 'returns expiration confirmation error message' do
            expect(json['errors']['password_confirmation']).to include(
              I18n.t('errors.messages.confirmation', attribute: 'Password')
            )
          end
        end

        context 'when password is blank' do
          before do
            user.send_reset_password_instructions
            put :update, params: {
              reset_password_token: user.reset_password_token,
              password: {password: ''}
            }
          end

          it 'returns 422 http status code' do
            expect(response).to have_http_status(422)
          end

          it 'returns expiration confirmation error message' do
            expect(json['errors']['password']).to include(I18n.t('rails_jwt_auth.errors.invalid'))
          end
        end
      end
    end
  end
end
