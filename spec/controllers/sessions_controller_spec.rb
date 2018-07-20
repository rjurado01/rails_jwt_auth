require 'rails_helper'
require 'rails_jwt_auth/jwt_manager'

describe RailsJwtAuth::SessionsController do
  %w[ActiveRecord Mongoid].each do |orm|
    context "when use #{orm}" do
      before :all do
        RailsJwtAuth.model_name = "#{orm}User"
      end

      let(:json) { JSON.parse(response.body) }
      let(:user) { FactoryBot.create("#{orm.underscore}_user") }
      let(:unconfirmed_user) { FactoryBot.create("#{orm.underscore}_unconfirmed_user") }

      describe 'POST #create' do
        context 'when all is ok' do
          before do
            post :create, params: {session: {email: user.email, password: '12345678'}}
          end

          it 'returns 201 status code' do
            expect(response.status).to eq(201)
          end

          it 'returns valid authentication token' do
            jwt = json['session']['jwt']
            token = RailsJwtAuth::JwtManager.decode(jwt)[0]['auth_token']
            expect(token).to eq(user.reload.auth_tokens.last)
          end
        end

        context 'when use diferent auth_field' do
          before { RailsJwtAuth.auth_field_name = 'username' }
          after { RailsJwtAuth.auth_field_name = 'email' }

          it 'returns 201 status code' do
            post :create, params: {session: {username: user.username, password: '12345678'}}
            expect(response.status).to eq(201)
          end
        end

        context 'when parameters are blank' do
          it 'raises ActionController::ParameterMissing' do
            expect { post :create, params: {} }.to raise_error ActionController::ParameterMissing
          end
        end

        context 'when email is invalid' do
          before do
            post :create, params: {session: {email: 'invalid@email.com', password: '12345678'}}
          end

          it 'returns 422 status code' do
            expect(response.status).to eq(422)
          end

          it 'returns error message' do
            expect(json['errors']['session'].first['error']).to eq 'invalid_session'
          end
        end

        context 'when password is invalid' do
          before do
            post :create, params: {session: {email: user.email, password: 'invalid'}}
          end

          it 'returns 422 status code' do
            expect(response.status).to eq(422)
          end

          it 'returns error message' do
            expect(json['errors']['session'].first['error']).to eq 'invalid_session'
          end
        end

        context 'when user is not confirmed' do
          before do
            post :create, params: {session: {email: unconfirmed_user.email, password: '12345678'}}
          end

          it 'returns 422 status code' do
            expect(response.status).to eq(422)
          end

          it 'returns error message' do
            expect(json['errors']['session'].first['error']).to eq 'unconfirmed'
          end
        end
      end

      describe 'Delete #destroy' do
        context 'when user is logged' do
          before do
            user.regenerate_auth_token
            jwt_info = [{auth_token: user.auth_tokens.first}]

            allow(controller).to receive(:current_user).and_return(user)
            allow(controller).to receive(:authenticate!).and_return(true)
            allow(RailsJwtAuth::JwtManager).to receive(:decode_from_request).and_return(jwt_info)

            delete :destroy
          end

          it 'returns 204 status code' do
            expect(response.status).to eq(204)
          end

          it 'removes user token' do
            expect(user.reload.auth_tokens).to eq([])
          end
        end

        context 'when user is not logged' do
          it 'raises RailsJwtAuth::NotAuthorized exception' do
            expect { delete :destroy }.to raise_error RailsJwtAuth::NotAuthorized
          end
        end
      end
    end
  end
end
