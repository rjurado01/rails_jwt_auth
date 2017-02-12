require 'rails_helper'

describe RailsJwtAuth::SessionsController do
  context 'when use ActiveRecord model' do
    before :all do
      RailsJwtAuth.model_name = ActiveRecordUser.to_s

      ActiveRecordUser.destroy_all
      @user = ActiveRecordUser.create(email: 'user@emailc.com', password: '12345678')
    end

    let(:json) { JSON.parse(response.body) }

    describe 'POST #create' do
      context 'when parameters are valid' do
        before do
          post :create, params: {email: @user.email, password: '12345678'}
        end

        it 'returns 201 status code' do
          expect(response.status).to eq(201)
        end

        it 'returns valid authentication token' do
          jwt = json['session']['jwt']
          token = RailsJwtAuth::Jwt::Manager.decode(jwt)[0]['auth_token']
          expect(token).to eq(@user.reload.auth_tokens.last)
        end
      end

      context 'when parameters are invalid' do
        before do
          post :create, params: {}
        end

        it 'returns 422 status code' do
          expect(response.status).to eq(422)
        end

        it 'returns error message' do
          expect(json).to eq('session' => {'error' => 'Invalid email / password'})
        end
      end
    end

    describe 'Delete #destroy' do
      context 'when user is logged' do
        before do
          sign_in(@user)
          delete :destroy
        end

        it 'returns 204 status code' do
          expect(response.status).to eq(204)
        end

        it 'removes user token' do
          expect(@user.reload.auth_tokens).to eq([])
        end
      end

      context 'when user is not logged' do
        before do
          sign_out
          delete :destroy
        end

        it 'returns 401 status code' do
          expect(response.status).to eq(401)
        end
      end
    end
  end

  context 'when use Montoid model' do
    before :all do
      RailsJwtAuth.model_name = MongoidUser.to_s

      MongoidUser.destroy_all
      @user = MongoidUser.create(email: 'user@emailc.com', password: '12345678')
    end

    let(:json) { JSON.parse(response.body) }

    describe 'POST #create' do
      context 'when parameters are valid' do
        before do
          post :create, params: {email: @user.email, password: '12345678'}
        end

        it 'returns 201 status code' do
          expect(response.status).to eq(201)
        end

        it 'returns valid authentication token' do
          jwt = json['session']['jwt']
          token = RailsJwtAuth::Jwt::Manager.decode(jwt)[0]['auth_token']
          expect(token).to eq(@user.reload.auth_tokens.last)
        end
      end

      context 'when parameters are invalid' do
        before do
          post :create, params: {}
        end

        it 'returns 422 status code' do
          expect(response.status).to eq(422)
        end

        it 'returns error message' do
          expect(json).to eq('session' => {'error' => 'Invalid email / password'})
        end
      end
    end

    describe 'Delete #destroy' do
      context 'when user is logged' do
        before do
          sign_in(@user)
          delete :destroy
        end

        it 'returns 204 status code' do
          expect(response.status).to eq(204)
        end

        it 'removes user token' do
          expect(@user.reload.auth_tokens).to eq([])
        end
      end

      context 'when user is not logged' do
        before do
          sign_out
          delete :destroy
        end

        it 'returns 401 status code' do
          expect(response.status).to eq(401)
        end
      end
    end
  end
end
