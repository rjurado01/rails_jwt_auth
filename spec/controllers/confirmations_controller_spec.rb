require 'rails_helper'

describe RailsJwtAuth::ConfirmationsController do
  %w[ActiveRecord Mongoid].each do |orm|
    context "when use #{orm}" do
      before(:all) { initialize_orm(orm) }

      let(:json) { JSON.parse(response.body) }
      let!(:user) { FactoryBot.create("#{orm.underscore}_unconfirmed_user") }

      describe 'POST #create' do
        context 'when sends valid email' do
          it 'returns 201 http status code' do
            post :create, params: {confirmation: {email: user.email}}
            expect(response).to have_http_status(204)
          end

          it 'sends new confirmation email with new token' do
            expect(RailsJwtAuth).to receive(:send_email).with(:confirmation_instructions, anything)

            old_token = user.confirmation_token
            post :create, params: {confirmation: {email: user.email}}
            expect(user.reload.confirmation_token).not_to eq(old_token)
          end
        end

        context 'when send not registered email and avoid_email_errors is false' do
          before do
            RailsJwtAuth.avoid_email_errors = false
            post :create, params: {confirmation: {email: 'not.found@email.com'}}
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
            post :create, params: {confirmation: {email: 'invalid'}}
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
            post :create, params: {confirmation: {email: 'not.found@email.com'}}
          end

          it 'returns 204 http status code' do
            expect(response).to have_http_status(204)
          end
        end

        context 'when send invalid email and avoid_email_errors is true' do
          before do
            post :create, params: {confirmation: {email: 'invalid'}}
          end

          it 'returns 204 http status code' do
            expect(response).to have_http_status(422)
          end

          it 'returns format error' do
            expect(json['errors']['email'].first['error']).to eq 'format'
          end
        end



        context 'when email is already confirmed' do
          before do
            user.confirm
            post :create, params: {confirmation: {email: user.email}}
          end

          it 'returns 422 http status code' do
            expect(response).to have_http_status(422)
          end

          it 'returns expiration confirmation error message' do
            expect(json['errors']['email'].first['error']).to eq 'already_confirmed'
          end
        end
      end

      describe 'PUT #update' do
        context 'when sends valid confirmation token' do
          before do
            put :update, params: {id: user.confirmation_token}
          end

          it 'returns 204 http status code' do
            expect(response).to have_http_status(204)
          end

          it 'confirms user' do
            expect(user.reload.confirmed?).to be_truthy
          end
        end

        context 'when sends invalid confirmation token' do
          before do
            put :update, params: {id: 'invalid'}
          end

          it 'returns 404 http status code' do
            expect(response).to have_http_status(404)
          end
        end

        context 'when sends expired confirmation token' do
          before do
            user.update(confirmation_sent_at: Time.current - 1.month)
            put :update, params: {id: user.confirmation_token}
          end

          it 'returns 422 http status code' do
            expect(response).to have_http_status(422)
          end

          it 'returns expiration confirmation error message' do
            expect(json['errors']['confirmation_token'].first['error']).to eq 'expired'
          end

          it 'does not confirm user' do
            expect(user.reload.confirmed?).to be_falsey
          end
        end
      end
    end
  end
end
