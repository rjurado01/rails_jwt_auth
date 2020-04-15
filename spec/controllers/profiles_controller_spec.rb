require 'rails_helper'

include RailsJwtAuth::SpecHelpers

RSpec.describe RailsJwtAuth::ProfilesController do
  %w[ActiveRecord Mongoid].each do |orm|
    context "Using #{orm}" do
      before(:all) { initialize_orm(orm) }

      let(:json) { JSON.parse(response.body).first[1] }
      let(:errors) { JSON.parse(response.body)['errors'] }
      let(:user) { FactoryBot.create("#{orm.underscore}_user") }

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

          it 'allows update password' do
            put :update, params: {profile: {current_password: '12345678', password: 'new_password'}}
            expect(response).to have_http_status(204)
          end

          it 'validates current password presence' do
            put :update, params: {profile: {password: 'new_password'}}
            expect(response).to have_http_status(422)
            expect(errors['current_password'].first['error']).to eq 'blank'
          end

          it 'validates current password match' do
            put :update, params: {profile: {current_password: 'invalid', password: 'new_password'}}
            expect(response).to have_http_status(422)
            expect(errors['current_password'].first['error']).to eq 'invalid'
          end

          it 'validates password confirmation' do
            put :update, params: {profile: {
              current_password: 'invalid',
              password: 'new_password',
              password_confirmation: 'invalid'
            }}

            expect(response).to have_http_status(422)
            expect(errors['password_confirmation'].first['error']).to eq 'confirmation'
          end
        end

        context 'when user is not logged' do
          it 'raises RailsJwtAuth::NotAuthorized exception' do
            expect { put :update, params: {} }.to raise_error RailsJwtAuth::NotAuthorized
          end
        end
      end
    end
  end
end
