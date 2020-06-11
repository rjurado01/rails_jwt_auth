require 'rails_helper'

RSpec.describe RailsJwtAuth::InvitationsController do
  %w[ActiveRecord Mongoid].each do |orm|
    context "Using #{orm}" do
      before(:all) { initialize_orm(orm) }

      let(:invited_user) { RailsJwtAuth.model.invite email: 'valid@example.com' }
      let(:json) { JSON.parse(response.body) }

      describe 'GET #show' do
        context 'when token is valid' do
          it 'returns 204 http status code' do
            get :show, params: {id: invited_user.invitation_token}
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
            travel_to(RailsJwtAuth.invitation_expiration_time.ago - 1.second) do
              invited_user
            end

            get :show, params: {id: invited_user.invitation_token}
            expect(response).to have_http_status(410)
          end
        end
      end

      describe 'POST #create' do
        context 'when user is authenticated' do
          before do
            allow(subject).to receive(:authenticate!).and_return(true)
          end

          context 'without passing email as param' do
            it 'raises ActiveRecord::ParameterMissing' do
              expect { post :create, params: {} }.to raise_error ActionController::ParameterMissing
            end
          end
            let(:email) { 'valid@example.com' }

          context 'passing email as param' do
            context 'without existing user' do
              it 'returns HTTP 201 Created' do
                post :create, params: {invitation: {email: 'test@example.com'}}
                expect(response).to have_http_status(:no_content)
              end
            end

            context 'with already invited user' do
              it 'returns HTTP 201 Created' do
                post :create, params: {invitation: {email: invited_user.email}}
                expect(response).to have_http_status(:no_content)
              end
            end

            context 'with already registered user' do
              let(:registered_user) { FactoryBot.create "#{orm.underscore}_user" }

              it 'returns HTTP 422 Unprocessable Entity' do
                post :create, params: {invitation: {email: registered_user.email}}
                expect(response).to have_http_status(:unprocessable_entity)
              end
            end
          end
        end

        context 'when user is not authenticated' do
          it 'raises RailsJwtAuth::NotAuthorized' do
            expect { post :create, params: {} }.to raise_error RailsJwtAuth::NotAuthorized
          end
        end
      end

      describe 'PUT #update' do
        context 'when invited user' do
          context 'with all params' do
            before do
              put :update, params: {
                id: invited_user.invitation_token,
                invitation: {password: 'abcdef', password_confirmation: 'abcdef'}
              }
            end

            it 'returns HTTP 204 No content' do
              expect(response).to have_http_status(:no_content)
            end

            it 'updates users password' do
              expect(invited_user.password_digest).to_not eq(invited_user.reload.password_digest)
            end

            it 'deletes the token of the user' do
              expect(invited_user.reload.invitation_token).to be_nil
            end
          end

          context 'with invalid token' do
            before do
              put :update, params: {
                id: 'invalid_token',
                invitation: {password: 'abcdef', password_confirmation: 'abcdef'}
              }
            end

            it 'returns HTTP 404' do
              expect(response).to have_http_status(404)
            end
          end

          context 'without password' do
            before do
              put :update, params: {
                id: invited_user.invitation_token,
                invitation: {password: ''}
              }
            end

            it 'returns HTTP 422 with password error' do
              expect(response).to have_http_status(422)
              expect(json['errors']['password'].first['error']).to eq 'blank'
            end
          end

          context 'with expired invitation' do
            it 'returns HTTP 422 Unprocessable Entity' do
              id = invited_user.invitation_token

              travel_to(3.days.from_now) do
                put :update, params: {
                  id: id,
                  invitation: {password: 'abcdef', password_confirmation: 'abcdef'}
                }
              end

              expect(response).to have_http_status(:unprocessable_entity)
            end
          end

          context 'with mismatching passwords' do
            before do
              put :update, params: {
                id: invited_user.invitation_token,
                invitation: {password: 'abcdef', password_confirmation: ''}
              }
            end

            it 'returns HTTP 422 Unprocessable Entity' do
              expect(response).to have_http_status(:unprocessable_entity)
            end

            it 'the token keeps in the user' do
              expect(invited_user.invitation_token).to eq(invited_user.reload.invitation_token)
            end
          end
        end
      end
    end
  end
end
