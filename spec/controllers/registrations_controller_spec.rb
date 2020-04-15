require 'rails_helper'

describe RailsJwtAuth::RegistrationsController do
  %w[ActiveRecord Mongoid].each do |orm|
    context "when use #{orm}" do
      before(:all) { initialize_orm(orm) }

      before do
        allow_any_instance_of(RailsJwtAuth.model)
          .to(receive(:send_confirmation_instructions).and_return(true))
      end

      let(:root) { RailsJwtAuth.model_name.underscore }

      describe 'POST #create' do
        before do
          RailsJwtAuth.model.destroy_all
        end

        let(:json) { JSON.parse(response.body)['errors'] }

        context 'when parameters are blank' do
          before do
            post :create, params: {root => {email: '', password: ''}}
          end

          it 'returns 422 status code' do
            expect(response.status).to eq(422)
          end

          it 'returns errors messages' do
            expect(json['email'].first['error']).to eq 'blank'
            expect(json['password'].first['error']).to eq 'blank'
          end
        end

        context 'when parameters are valid' do
          before do
            params = {email: 'user@email.com', password: '12345678'}
            post :create, params: {root => params}
          end

          let(:json) { JSON.parse(response.body)[root] }

          it 'creates new user' do
            expect(RailsJwtAuth.model.count).to eq(1)
          end

          it 'returns 201 status code' do
            expect(response.status).to eq(201)
          end

          it 'returns user info' do
            expect(json['email']).to eq('user@email.com')
          end
        end
      end
    end
  end
end
