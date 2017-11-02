require 'rails_helper'

describe RailsJwtAuth::SessionsController do
  %w(Mongoid).each do |orm|
    context "when use #{orm}" do
      before :all do
        RailsJwtAuth.model_name = "#{orm}User"
      end

      let(:json) { JSON.parse(response.body) }
      let(:user) { FactoryGirl.create("#{orm.underscore}_user") }
      let(:unconfirmed_user) { FactoryGirl.create("#{orm.underscore}_unconfirmed_user") }

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
            session_id = RailsJwtAuth::Jwt::Manager.decode(jwt)[0]['session_id']
            expect(session_id).to eq(user.reload.sessions.last[:id])
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
            expect(json).to eq('session' => 'is required')
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
            error = I18n.t('rails_jwt_auth.errors.create_session', field: RailsJwtAuth.auth_field_name)
            expect(json['errors']['session']).to include(error)
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
            error = I18n.t('rails_jwt_auth.errors.create_session', field: RailsJwtAuth.auth_field_name)
            expect(json['errors']['session']).to include(error)
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
            expect(json).to eq('session' => 'is required')
          end
        end
      end

      describe 'Delete #destroy' do
        context 'when user is logged' do
          before do
            session = user.create_session
            jwt = RailsJwtAuth::Jwt::Manager.encode(session_id: session[:id])
            @request.headers['HTTP_AUTHORIZATION'] = jwt

            sign_in user

            delete :destroy
          end

          it 'returns 204 status code' do
            expect(response.status).to eq(204)
          end

          it 'removes user token' do
            expect(user.reload.sessions.size).to eq(0)
          end
        end

        context 'when user is not logged' do
          before do
            delete :destroy
          end

          it 'returns 401 status code' do
            expect(response.status).to eq(401)
          end
        end
      end
    end
  end
end
