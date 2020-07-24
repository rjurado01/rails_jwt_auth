require 'rails_helper'

include RailsJwtAuth::SpecHelpers

RSpec.describe RailsJwtAuth::ProfilesController do
  %w[ActiveRecord Mongoid].each do |orm|
    context "Using #{orm}" do
      before(:all) { initialize_orm(orm) }

      let(:password) { '12345678' }
      let(:new_password) { 'new12345678' }

      let(:json) { JSON.parse(response.body).first[1] }
      let(:errors) { JSON.parse(response.body)['errors'] }
      let(:user) { FactoryBot.create("#{orm.underscore}_user", password: password) }

      describe 'GET #show' do
        context 'when user is logged' do
          before do
            sign_in user
          end

          it 'returns user info' do
            get :show
            expect(response).to have_http_status(200)
            expect(json['email']).to eq user.email
          end
        end

        context 'when user is not logged' do
          it 'raises RailsJwtAuth::NotAuthorized exception' do
            expect { get :show }.to raise_error RailsJwtAuth::NotAuthorized
          end
        end
      end

      describe 'PUT #update' do
        context 'when user is logged' do
          before do
            sign_in user
          end

          it 'allows update normal fields' do
            allow(controller).to receive(:profile_update_params).and_return(username: 'blue')
            put :update, params: {profile: {username: 'blue'}}
            expect(response).to have_http_status(204)
            expect(user.reload.username).to eq('blue')
          end

          it 'ignore email and password fields' do
            put :update, params: {profile: {
              email: 'new@email.com',
              current_password: password,
              password: new_password,
              password_confirmation: new_password
            }}

            expect(response).to have_http_status(204)
            expect(user.reload.unconfirmed_email).to be_nil
            expect(user.authenticate(password)).not_to be_falsey
          end
        end

        context 'when user is not logged' do
          it 'raises RailsJwtAuth::NotAuthorized exception' do
            expect { put :update, params: {} }.to raise_error RailsJwtAuth::NotAuthorized
          end
        end
      end

      describe 'PUT #password' do
        before do
          allow_any_instance_of(RailsJwtAuth::AuthenticableHelper)
            .to receive(:jwt_payload).and_return('auth_token' => 'xxx')
        end

        context 'when user is logged' do
          before do
            sign_in user
          end

          it 'allows update password' do
            put :password, params: {profile: {current_password: password, password: new_password}}
            expect(response).to have_http_status(204)
          end

          it 'validates current password presence' do
            put :password, params: {profile: {password: new_password}}
            expect(response).to have_http_status(422)
            expect(errors['current_password'].first['error']).to eq 'blank'
          end

          it 'validates current password match' do
            put :password, params: {profile: {current_password: 'invalid', password: new_password}}
            expect(response).to have_http_status(422)
            expect(errors['current_password'].first['error']).to eq 'invalid'
          end

          it 'validates password confirmation' do
            put :password, params: {profile: {
              current_password: 'invalid',
              password: new_password,
              password_confirmation: 'invalid'
            }}

            expect(response).to have_http_status(422)
            expect(errors['password_confirmation'].first['error']).to eq 'confirmation'
          end

          it 'close other sessions' do
            put :password, params: {profile: {current_password: password, password: new_password}}

            expect(user.reload.auth_tokens).to eq(['xxx'])
          end
        end

        context 'when user is not logged' do
          it 'raises RailsJwtAuth::NotAuthorized exception' do
            expect { put :password, params: {} }.to raise_error RailsJwtAuth::NotAuthorized
          end
        end
      end

      describe 'PUT #email' do
        context 'when user is logged' do
          before do
            sign_in user
          end

          it 'allows update email' do
            put :email, params: {profile: {password: password, email: 'new@email.com'}}
            expect(response).to have_http_status(204)
            expect(user.reload.unconfirmed_email).to eq('new@email.com')
          end
        end

        context 'when user is not logged' do
          it 'raises RailsJwtAuth::NotAuthorized exception' do
            expect { put :email, params: {} }.to raise_error RailsJwtAuth::NotAuthorized
          end
        end
      end
    end
  end
end
