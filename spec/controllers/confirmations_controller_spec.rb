require 'rails_helper'

describe RailsJwtAuth::ConfirmationsController do
  %w(ActiveRecord Mongoid).each do |orm|
    context "when use #{orm}" do
      before :all do
        RailsJwtAuth.model_name = "#{orm}User"
      end

      let(:json) { JSON.parse(response.body) }
      let(:user) { FactoryGirl.create("#{orm.underscore}_unconfirmed_user") }

      describe 'GET #show' do
        context 'when sends valid confirmation token' do
          before do
            get :show, params: {confirmation_token: user.confirmation_token}
          end

          it 'returns 200 http status code' do
            expect(response).to have_http_status(204)
          end

          it 'confirms user' do
            expect(user.reload.confirmed?).to be_truthy
          end
        end

        context 'when sends invalid confirmation token' do
          before do
            get :show, params: {confirmation_token: 'invalid'}
          end

          it 'returns 404 http status code' do
            expect(response).to have_http_status(404)
          end

          it 'does not confirm user' do
            expect(user.reload.confirmed?).to be_falsey
          end
        end

        context 'when sends expired confirmation token' do
          before do
            user.update_attribute(:confirmation_sent_at, Time.now - 1.month)
            get :show, params: {confirmation_token: user.confirmation_token}
          end

          it 'returns 422 http status code' do
            expect(response).to have_http_status(422)
          end

          it 'returns expiration confirmation error message' do
            expect(json['errors']['confirmation_token'].first).to(
              eq(I18n.t('rails_jwt_auth.errors.confirmation_expired'))
            )
          end

          it 'does not confirm user' do
            expect(user.reload.confirmed?).to be_falsey
          end
        end

        context 'when email is already confirmed' do
          before do
            user.confirm!
            get :show, params: {confirmation_token: user.confirmation_token}
          end

          it 'returns 422 http status code' do
            expect(response).to have_http_status(422)
          end

          it 'returns expiration confirmation error message' do
            expect(json['errors']['email'].first).to(
              eq(I18n.t('rails_jwt_auth.errors.already_confirmed'))
            )
          end
        end

        context 'when sends invalid confirmation token' do
          before do
            get :show
          end

          it 'returns 400 http status code' do
            expect(response).to have_http_status(400)
          end

          it 'does not confirm user' do
            expect(user.reload.confirmed?).to be_falsey
          end
        end
      end

      describe 'POST #create' do
        context 'when sends valid email' do
          it 'returns 201 http status code' do
            post :create, params: {confirmation: {email: user.email}}
            expect(response).to have_http_status(204)
          end

          it 'sends new confirmation email with new token' do
            class Mock
              def deliver
              end
            end

            expect(RailsJwtAuth::Mailer).to receive(:confirmation_instructions)
              .with(user).and_return(Mock.new)

            old_token = user.confirmation_token
            post :create, params: {confirmation: {email: user.email}}
            expect(user.reload.confirmation_token).not_to eq(old_token)
          end
        end

        context 'when send invalid email' do
          it 'returns 404 http status code' do
            post :create, params: {confirmation: {email: 'invalid'}}
            expect(response).to have_http_status(404)
          end
        end
      end
    end
  end
end
