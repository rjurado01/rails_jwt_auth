require 'rails_helper'

RSpec.describe RailsJwtAuth::InvitationsController do
  %w[ActiveRecord Mongoid].each do |orm|
    context "Using #{orm}" do
      before :all do
        RailsJwtAuth.model_name = "#{orm}User"
      end

      describe 'POST #create' do
        context 'without passing email as param' do
          subject { post :create, params: {} }

          it { is_expected.to have_http_status(:unprocessable_entity) }
        end

        context 'passing email as param' do
          let(:email) { 'valid@example.com' }

          context 'without existing user' do
            it 'returns HTTP 201 Created' do
              post :create, params: {invitation: {email: email}}
              expect(response).to have_http_status(:no_content)
            end
          end

          context 'with already invited user' do
            let(:user) { RailsJwtAuth.model.invite! email: 'test@example.com' }

            it 'returns HTTP 201 Created' do
              post :create, params: {invitation: {email: user.email}}
              expect(response).to have_http_status(:no_content)
            end
          end

          context 'with already registered user' do
            let(:user) { FactoryGirl.create "#{orm.underscore}_user" }

            it 'returns HTTP 422 Unprocessable Entity' do
              post :create, params: {invitation: {email: user.email}}
              expect(response).to have_http_status(:unprocessable_entity)
            end
          end
        end
      end

      describe 'PUT #update' do
        context 'when invited user' do
          let(:user) { RailsJwtAuth.model.invite! email: 'valid@example.com' }
          context 'with all params' do
            before do
              put :update, params: {accept_invitation: {
                invitation_token: user.invitation_token,
                password: 'abcdef',
                password_confirmation: 'abcdef'
              }}
            end

            it 'returns HTTP 204 No content' do
              expect(response).to have_http_status(:no_content)
            end

            it 'updates users password' do
              expect(user.password_digest).to_not eq(user.reload.password_digest)
            end

            it 'deletes the token of the user' do
              expect(user.reload.invitation_token).to be_nil
            end
          end

          context 'with invitation token' do
            before do
              put :update, params: {accept_invitation: {invitation_token: user.invitation_token}}
            end

            it 'returns HTTP 204 No content' do
              expect(response).to have_http_status(:no_content)
            end

            it 'deletes the token of the user' do
              expect(user.reload.invitation_token).to be_nil
            end
          end

          context 'without token' do
            before do
              put :update, params: {accept_invitation: {}}
            end

            it 'returns HTTP 422 Unprocessable Entity' do
              expect(response).to have_http_status(:unprocessable_entity)
            end

            it 'the token keeps in the user' do
              expect(user.invitation_token).to eq(user.reload.invitation_token)
            end
          end

          context 'with expired invitation' do
            let!(:invited_user) { RailsJwtAuth.model.invite! email: 'test@example.com' }
            it 'returns HTTP 422 Unprocessable Entity' do
              Timecop.travel(3.days.from_now) do
                put :update, params: {accept_invitation: {
                  invitation_token: invited_user.invitation_token
                }}
              end
              expect(response).to have_http_status(:unprocessable_entity)
            end
          end

          context 'with mismatching passwords' do
            before do
              put :update, params: {accept_invitation: {
                invitation_token: user.invitation_token,
                password: 'abcdef',
                password_confirmation: ''
              }}
            end

            it 'returns HTTP 422 Unprocessable Entity' do
              expect(response).to have_http_status(:unprocessable_entity)
            end

            it 'the token keeps in the user' do
              expect(user.invitation_token).to eq(user.reload.invitation_token)
            end
          end
        end
      end
    end
  end
end
