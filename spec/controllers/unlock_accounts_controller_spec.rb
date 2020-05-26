require 'rails_helper'

describe RailsJwtAuth::UnlockAccountsController do
  %w[ActiveRecord Mongoid].each do |orm|
    context "when use #{orm}" do
      before(:all) { initialize_orm(orm) }

      let(:user) {
        FactoryBot.create(
          "#{orm.underscore}_user",
          locked_at: 2.minutes.ago,
          failed_attempts: 3,
          first_failed_attempt_at: 3.minutes.ago,
          unlock_token: SecureRandom.base58(24)
        )
      }

      describe 'PUT #update' do
        context 'when send a valid unlock_token' do
          before do
            put :update, params: {id: user.unlock_token}
          end

          it 'returns 204 http status code' do
            expect(response).to have_http_status 204
          end

          it 'unlocks access' do
            user.reload
            expect(user.locked_at).to be_nil
            expect(user.failed_attempts).to eq 0
            expect(user.first_failed_attempt_at).to be_nil
            expect(user.unlock_token).to be_nil
          end
        end

        context 'when unlock_token is invalid' do
          before do
            put :update, params: {id: 'invalid'}
          end

          it 'returns 404 http status code' do
            expect(response).to have_http_status 404
          end
        end
      end
    end
  end
end
