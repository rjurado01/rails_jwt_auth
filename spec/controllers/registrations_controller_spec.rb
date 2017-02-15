require 'rails_helper'

describe RailsJwtAuth::RegistrationsController do
  %w(ActiveRecord Mongoid).each do |orm|
    context "when use #{orm}" do
      before :all do
        RailsJwtAuth.model_name = "#{orm}User"
      end

      before do
        allow_any_instance_of(RailsJwtAuth.model)
          .to(receive(:send_confirmation_instructions).and_return(true))
      end

      let(:root) { RailsJwtAuth.model_name.underscore }
      let(:json) { JSON.parse(response.body)[root] }

      describe 'POST #create' do
        before do
          RailsJwtAuth.model.destroy_all
        end

        context 'when parameters are invalid' do
          before do
            post :create, params: {root => {}}
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
            params = {email: 'user@email.com', password: '12345678'}
            post :create, params: {root => params}
          end

          it 'creates new user' do
            expect(RailsJwtAuth.model.count).to eq(1)
          end

          it 'returns 201 status code' do
            expect(response.status).to eq(201)
          end

          it 'returns user info' do
            expect(json['id']).to eq(RailsJwtAuth.model.first.id.to_s)
            expect(json['email']).to eq('user@email.com')
          end
        end
      end
    end
  end
end
