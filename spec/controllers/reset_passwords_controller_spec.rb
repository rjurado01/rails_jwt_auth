require 'rails_helper'

describe RailsJwtAuth::ResetPasswordsController do
  %w[ActiveRecord Mongoid].each do |orm|
    context "when use #{orm}" do
      before(:all) { initialize_orm(orm) }

      let(:json) { JSON.parse(response.body) }
      let(:user) { FactoryBot.create("#{orm.underscore}_user", password: '12345678') }
      let(:unconfirmed_user) { FactoryBot.create("#{orm.underscore}_unconfirmed_user") }

      describe 'GET #show' do
        context 'when token is valid' do
          it 'returns 204 http status code' do
            user.send_reset_password_instructions
            get :show, params: {id: user.reset_password_token}
            expect(response).to have_http_status(204)
          end
        end

        context 'when token is invalid' do
          it 'returns 404 http status code' do
            get :show, params: {id: 'invalid'}
            expect(response).to have_http_status(404)
          end
        end

        context 'when token is expired' do
          it 'returns 410 http status code' do
            travel_to(RailsJwtAuth.reset_password_expiration_time.ago - 1.second) do
              user.send_reset_password_instructions
            end

            get :show, params: {id: user.reset_password_token}
            expect(response).to have_http_status(410)
          end
        end
      end

      describe 'POST #create' do
        context 'when sends valid email' do
          it 'returns 204 http status code' do
            post :create, params: {reset_password: {email: user.email}}
            expect(response).to have_http_status(204)
          end

          it 'upper case and down case are ignored' do
            post :create, params: {reset_password: {email: user.email.upcase}}
            expect(response).to have_http_status(204)
          end

          it 'leading and trailing spaces are ignored' do
            post :create, params: {reset_password: {email: "  #{user.email}  "}}
            expect(response).to have_http_status(204)
          end

          it 'sends new reset_password email with new token' do
            expect(RailsJwtAuth).to receive(:send_email)
              .with(:reset_password_instructions, anything)

            old_token = user.reset_password_token
            post :create, params: {reset_password: {email: user.email}}
            expect(user.reload.reset_password_token).not_to eq(old_token)
          end

          context 'when user is unconfirmed' do
            it 'returns 422 http status code' do
              post :create, params: {reset_password: {email: unconfirmed_user.email}}
              expect(response).to have_http_status(422)
            end

            it 'returns unconfirmed error message' do
              post :create, params: {reset_password: {email: unconfirmed_user.email}}
              expect(json['errors']['email'].first['error']).to eq 'unconfirmed'
            end
          end
        end

        context 'when send not registered email and avoid_email_errors is false' do
          before do
            RailsJwtAuth.avoid_email_errors = false
            post :create, params: {reset_password: {email: 'not.found@email.com'}}
          end

          it 'returns 422 http status code' do
            expect(response).to have_http_status(422)
          end

          it 'returns not found error' do
            expect(json['errors']['email'].first['error']).to eq 'not_found'
          end
        end

        context 'when send invalid email and avoid_email_errors is false' do
          before do
            RailsJwtAuth.avoid_email_errors = false
            post :create, params: {reset_password: {email: 'invalid'}}
          end

          it 'returns 422 http status code' do
            expect(response).to have_http_status(422)
          end

          it 'returns format error' do
            expect(json['errors']['email'].first['error']).to eq 'format'
          end
        end

        context 'when send not registered email and avoid_email_errors is true' do
          before do
            post :create, params: {reset_password: {email: 'not.found@email.com'}}
          end

          it 'returns 204 http status code' do
            expect(response).to have_http_status(204)
          end
        end

        context 'when send invalid email and avoid_email_errors is true' do
          before do
            post :create, params: {reset_password: {email: 'invalid'}}
          end

          it 'returns 204 http status code' do
            expect(response).to have_http_status(422)
          end

          it 'returns format error' do
            expect(json['errors']['email'].first['error']).to eq 'format'
          end
        end

        context 'when send empty email' do
          before do
            post :create, params: {reset_password: {email: ''}}
          end

          it 'returns 422 http status code' do
            expect(response).to have_http_status(422)
          end

          it 'returns not found error' do
            expect(json['errors']['email'].first['error']).to eq 'blank'
          end
        end
      end

      describe 'PUT #update' do
        context 'when send all params correctly' do
          before do
            user.send_reset_password_instructions
            put :update, params: {
              id: user.reset_password_token,
              reset_password: {password: 'new_password'}
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
            put :update, params: {id: 'invalid'}
          end

          it 'returns 404 http status code' do
            expect(response).to have_http_status 404
          end
        end

        context 'when password confirmation is invalid' do
          before do
            user.send_reset_password_instructions
            put :update, params: {
              id: user.reset_password_token,
              reset_password: {password: 'a', password_confirmation: 'b'}
            }
          end

          it 'returns 422 http status code' do
            expect(response).to have_http_status(422)
          end

          it 'returns confirmation error message' do
            expect(json['errors']['password_confirmation'].first['error']).to eq 'confirmation'
          end
        end

        context 'when password is blank' do
          before do
            user.send_reset_password_instructions
            put :update, params: {
              id: user.reset_password_token,
              reset_password: {password: ''}
            }
          end

          it 'returns 422 http status code' do
            expect(response).to have_http_status(422)
          end

          it 'returns blank error message' do
            expect(json['errors']['password'].first['error']).to eq 'blank'
          end
        end
      end
    end
  end
end
