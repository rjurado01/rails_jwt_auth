require 'rails_helper'

describe RailsJwtAuth::AuthenticableHelper, type: :helper do
  before :all do
    RailsJwtAuth.model_name = ActiveRecordUser.to_s
  end

  let(:user) { FactoryGirl.create(:active_record_user) }

  describe '#current_user' do
    it 'returns current user' do
      @current_user = user
      expect(helper.current_user).to eq(user)
    end
  end

  describe 'signed_in?' do
    it 'returns if there is current user' do
      expect(helper.signed_in?).to be_falsey
      @current_user = user
      expect(helper.signed_in?).to be_truthy
    end
  end

  describe '#authenticate!' do
    context 'when jwt is valid' do
      it 'loads current user' do
        jwt = RailsJwtAuth::JwtManager.encode(sub: user.id.to_s)
        helper.request.env['HTTP_AUTHORIZATION'] = "Bearer #{jwt}"
        expect { helper.authenticate! }.not_to raise_exception
        expect(helper.current_user.id) == user.id
      end
    end

    context 'when jwt is invalid' do
      it 'unauthorize!' do
        helper.request.env['HTTP_AUTHORIZATION'] = 'Bearer invalid.token'
        expect { helper.authenticate! }.to raise_exception(RailsJwtAuth::NotAuthorized)
      end
    end

    context 'when jwt is expired' do
      it 'unauthorize!' do
        RailsJwtAuth.jwt_expiration_time = 1.second
        jwt = RailsJwtAuth::JwtManager.encode(active_record_user: {id: user.id.to_s})

        Timecop.freeze(Date.today + 1) do
          helper.request.env['HTTP_AUTHORIZATION'] = "Bearer #{jwt}"
          expect { helper.authenticate! }.to raise_exception(RailsJwtAuth::NotAuthorized)
        end
      end
    end

    context 'when user does not exists' do
      it 'unauthorize!' do
        jwt = RailsJwtAuth::JwtManager.encode(active_record_user: {id: user.id.to_s})
        helper.request.env['HTTP_AUTHORIZATION'] = "Bearer #{jwt}"
        user.destroy
        expect { helper.authenticate! }.to raise_exception(RailsJwtAuth::NotAuthorized)
      end
    end
  end
end
