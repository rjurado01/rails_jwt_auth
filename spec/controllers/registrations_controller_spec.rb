require 'rails_helper'

describe RailsJwtAuth::RegistrationsController do
  context 'when use ActiveRecord model' do
    before :all do
      RailsJwtAuth.model_name = ActiveRecordUser.to_s
    end

    let(:json) { JSON.parse(response.body)['active_record_user'] }

    describe 'POST #create' do
      before do
        ActiveRecordUser.destroy_all
      end

      context 'when parameters are invalid' do
        before do
          post :create, params: {active_record_user: {}}
        end

        it 'returns 422 status code' do
          expect(response.status).to eq(422)
        end

        it 'returns error message' do
          expect(json).to eq('is required')
        end
      end

      context 'when parameters are valid' do
        before do
          post :create, params: {active_record_user: {email: 'user@email.com', password: '12345678'}}
        end

        it 'creates new user' do
          expect(ActiveRecordUser.count).to eq(1)
        end

        it 'returns 201 status code' do
          expect(response.status).to eq(201)
        end

        it 'returns user info' do
          expect(json['id']).to eq(ActiveRecordUser.first.id.to_s)
          expect(json['email']).to eq('user@email.com')
        end
      end
    end
  end

  context 'when use Montoid model' do
    before :all do
      RailsJwtAuth.model_name = MongoidUser.to_s
    end

    let(:json) { JSON.parse(response.body)['mongoid_user'] }

    describe 'POST #create' do
      before do
        MongoidUser.destroy_all
      end

      context 'when parameters are invalid' do
        before do
          post :create, params: {mongoid_user: {}}
        end

        it 'returns 422 status code' do
          expect(response.status).to eq(422)
        end

        it 'returns error message' do
          expect(json).to eq('is required')
        end
      end

      context 'when parameters are valid' do
        before do
          post :create, params: {mongoid_user: {email: 'user@email.com', password: '12345678'}}
        end

        it 'returns 201 status code' do
          expect(response.status).to eq(201)
        end

        it 'returns valid authentication token' do
          expect(json['id']).to eq(MongoidUser.first.id.to_s)
          expect(json['email']).to eq('user@email.com')
        end
      end
    end
  end
end
