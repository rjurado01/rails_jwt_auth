require 'rails_helper'
require 'rails_jwt_auth/jwt_manager'

describe RailsJwtAuth::OmniauthsController, type: :request do
  %w[ActiveRecord Mongoid].each do |orm|
    context "when use #{orm}" do
      before(:all) { initialize_orm(orm) }

      let(:json) { JSON.parse(response.body) }
      let(:user) { FactoryBot.create("#{orm.underscore}_user") }
      let(:unconfirmed_user) { FactoryBot.create("#{orm.underscore}_unconfirmed_user") }
      let(:locked_user) { FactoryBot.create("#{orm.underscore}_user", locked_at: 2.minutes.ago) }
      let(:dummy_oauth_middleware) { :google_oauth2 }
      let(:dummy_oauth_token) {{code: "1234567", redirect_uri: "postmessage"}}

      describe 'POST #callback' do
        context 'when all is ok' do
          before do
            allow("#{orm}User".constantize).to receive(:from_omniauth).and_return(user)
            post oauth_callback_path(provider: dummy_oauth_middleware)
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

        context 'when simultaneous sessions are 0' do
          it 'returns id instead of token' do
            allow("#{orm}User".constantize).to receive(:from_omniauth).and_return(user)
            allow(RailsJwtAuth).to receive(:simultaneous_sessions).and_return(0)
            post oauth_callback_path(provider: dummy_oauth_middleware)

            jwt = json['session']['jwt']
            payload = RailsJwtAuth::JwtManager.decode(jwt)[0]
            expect(payload['auth_token']).to be_nil
            expect(payload['id']).to eq(user.id.to_s)
          end
        end

        context 'when not defined from_omniauth' do
          before do
            post oauth_callback_path(provider: dummy_oauth_middleware)
          end

          it 'returns 422 status code' do
            expect(response.status).to eq(422)
          end

          it 'returns error message' do
            expect(json['errors']['session'].first['error']).to eq 'not_found'
          end
        end

        context 'when user is not confirmed' do
          before do
            allow("#{orm}User".constantize).to receive(:from_omniauth).and_return(unconfirmed_user)
            post oauth_callback_path(provider: dummy_oauth_middleware)
          end

          it 'returns 422 status code' do
            expect(response.status).to eq(422)
          end

          it 'returns error message' do
            expect(json['errors']['email'].first['error']).to eq 'unconfirmed'
          end
        end

        context 'when user is locked' do
          before do
            allow("#{orm}User".constantize).to receive(:from_omniauth).and_return(locked_user)
            post oauth_callback_path(provider: dummy_oauth_middleware)
          end

          it 'returns 422 status code' do
            expect(response.status).to eq(422)
          end

          it 'returns error message' do
            expect(json['errors']['email'].first['error']).to eq 'locked'
          end
        end
      end
    end
  end
end
