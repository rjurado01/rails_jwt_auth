require 'rails_helper'

describe RailsJwtAuth::TokensController do
  %w(Mongoid).each do |orm|
    context "when use #{orm}" do
      before :all do
        RailsJwtAuth.model_name = "#{orm}User"
      end

      let(:model_key) { RailsJwtAuth.model_name.to_s.underscore }
      let(:json) { JSON.parse(response.body) }
      let(:user) { FactoryGirl.create("#{orm.underscore}_user") }
      let(:unconfirmed_user) { FactoryGirl.create("#{orm.underscore}_unconfirmed_user") }

      describe 'POST #create' do
        context 'when all is ok' do
          before do
            post :create, params: {token: {email: user.email, password: '12345678'}}
          end

          it 'returns 201 status code' do
            expect(response.status).to eq(201)
          end

          it 'returns valid token' do
            jwt = json['jwt']
            payload = RailsJwtAuth::JwtManager.decode(jwt)[0]
            expect(payload['sub']).to eq(user.to_token_payload.stringify_keys['sub'])
          end
        end

        context 'when parameters are blank' do
          before do
            post :create, params: {}
          end

          it 'returns 422 status code' do
            expect(response.status).to eq(422)
          end

          it 'returns error message' do
            expect(json).to eq('token' => 'is required')
          end
        end

        context 'when email is invalid' do
          before do
            post :create, params: {token: {email: 'invalid@email.com', password: '12345678'}}
          end

          it 'returns 422 status code' do
            expect(response.status).to eq(422)
          end

          it 'returns error message' do
            error = I18n.t('rails_jwt_auth.errors.create_token', field: RailsJwtAuth.auth_field_name)
            expect(json['errors']['token']).to include(error)
          end
        end

        context 'when password is invalid' do
          before do
            post :create, params: {token: {email: user.email, password: 'invalid'}}
          end

          it 'returns 422 status code' do
            expect(response.status).to eq(422)
          end

          it 'returns error message' do
            error = I18n.t('rails_jwt_auth.errors.create_token', field: RailsJwtAuth.auth_field_name)
            expect(json['errors']['token']).to include(error)
          end
        end

        context 'when user is not confirmed' do
          before do
            post :create, params: {email: unconfirmed_user.email, password: '12345678'}
          end

          it 'returns 422 status code' do
            expect(response.status).to eq(422)
          end

          it 'returns error message' do
            expect(json).to eq('token' => 'is required')
          end
        end
      end
    end
  end
end
