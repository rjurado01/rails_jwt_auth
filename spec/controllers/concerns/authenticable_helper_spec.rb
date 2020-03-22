require 'rails_helper'
require 'rails_jwt_auth/jwt_manager'

describe RailsJwtAuth::AuthenticableHelper, type: :helper do
  describe '#current_user' do
    it 'returns current user' do
      @current_user = {name: 'name'}
      expect(helper.current_user).to eq(@current_user)
    end
  end

  describe '#jwt_payload' do
    it 'returns current jwt payload info' do
      @jwt_payload = {name: 'name'}
      expect(helper.jwt_payload).to eq(@jwt_payload)
    end
  end

  describe '#authenticate!' do
    before :all do
      RailsJwtAuth.model_name = ActiveRecordUser.to_s
      RailsJwtAuth.simultaneous_sessions = 1
    end

    let(:user) { FactoryBot.create(:active_record_user) }

    context 'when jwt is valid' do
      it 'success!' do
        token = user.regenerate_auth_token
        jwt = RailsJwtAuth::JwtManager.encode(auth_token: token)
        payload = RailsJwtAuth::JwtManager.decode(jwt)[0]
        helper.request.env['HTTP_AUTHORIZATION'] = "Bearer #{jwt}"

        helper.authenticate!
        expect(helper.current_user).to eq(user)
        expect(helper.jwt_payload).to eq(payload)
      end
    end

    context 'when jwt is invalid' do
      it 'fail!' do
        allow(RailsJwtAuth::JwtManager).to receive(:decode).and_raise(JWT::DecodeError)

        expect { helper.authenticate! }.to raise_error(RailsJwtAuth::NotAuthorized)
      end
    end

    context 'when jwt is expired' do
      it 'fail!' do
        allow(RailsJwtAuth::JwtManager).to receive(:decode).and_raise(JWT::ExpiredSignature)

        expect { helper.authenticate! }.to raise_error(RailsJwtAuth::NotAuthorized)
      end
    end

    context 'when jwt verification fail' do
      it 'fail!' do
        allow(RailsJwtAuth::JwtManager).to receive(:decode).and_raise(JWT::VerificationError)

        expect { helper.authenticate! }.to raise_error(RailsJwtAuth::NotAuthorized)
      end
    end

    context 'when session_token is invalid' do
      it 'fail!' do
        allow(RailsJwtAuth::JwtManager).to receive(:decode).and_return([{auth_token: 'invalid'}])

        expect { helper.authenticate! }.to raise_error(RailsJwtAuth::NotAuthorized)
      end
    end

    context 'when user is not found' do
      it 'fail!' do
        token = user.regenerate_auth_token
        jwt = RailsJwtAuth::JwtManager.encode(auth_token: token)
        helper.request.env['HTTP_AUTHORIZATION'] = "Bearer #{jwt}"

        user.delete
        expect { helper.authenticate! }.to raise_error(RailsJwtAuth::NotAuthorized)
      end
    end

    context 'when user is trackable' do
      it 'call update tracked fields' do
        user = Object.new
        user.extend RailsJwtAuth::Trackable

        allow(RailsJwtAuth::JwtManager).to receive(:decode).and_return([{}])
        allow(RailsJwtAuth.model).to receive(:get_by_token).and_return(user)

        expect(user).to receive(:update_tracked_fields!).and_return(true)
        helper.authenticate!
      end
    end
  end

  describe '#authenticate' do
    before :all do
      RailsJwtAuth.model_name = ActiveRecordUser.to_s
      RailsJwtAuth.simultaneous_sessions = 1
    end

    let(:user) { FactoryBot.create(:active_record_user) }

    context 'when jwt is valid' do
      it 'success!' do
        token = user.regenerate_auth_token
        jwt = RailsJwtAuth::JwtManager.encode(auth_token: token)
        payload = RailsJwtAuth::JwtManager.decode(jwt)[0]
        helper.request.env['HTTP_AUTHORIZATION'] = "Bearer #{jwt}"

        helper.authenticate
        expect(helper.current_user).to eq(user)
        expect(helper.jwt_payload).to eq(payload)
      end
    end

    context 'when jwt is invalid' do
      it 'fail!' do
        allow(RailsJwtAuth::JwtManager).to receive(:decode).and_raise(JWT::DecodeError)

        expect { helper.authenticate }.not_to raise_error
        expect(helper.current_user).to eq(nil)
      end
    end

    context 'when jwt is expired' do
      it 'fail!' do
        allow(RailsJwtAuth::JwtManager).to receive(:decode).and_raise(JWT::ExpiredSignature)

        expect { helper.authenticate }.not_to raise_error
        expect(helper.current_user).to eq(nil)
      end
    end

    context 'when jwt verification fail' do
      it 'fail!' do
        allow(RailsJwtAuth::JwtManager).to receive(:decode).and_raise(JWT::VerificationError)

        expect { helper.authenticate }.not_to raise_error
        expect(helper.current_user).to eq(nil)
      end
    end

    context 'when session_token is invalid' do
      it 'fail!' do
        allow(RailsJwtAuth::JwtManager).to receive(:decode).and_return([{auth_token: 'invalid'}])

        expect { helper.authenticate }.not_to raise_error
        expect(helper.current_user).to eq(nil)
      end
    end

    context 'when user is not found' do
      it 'fail!' do
        token = user.regenerate_auth_token
        jwt = RailsJwtAuth::JwtManager.encode(auth_token: token)
        helper.request.env['HTTP_AUTHORIZATION'] = "Bearer #{jwt}"

        user.delete
        expect { helper.authenticate }.not_to raise_error
        expect(helper.current_user).to eq(nil)
      end
    end

    context 'when user is trackable' do
      it 'call update tracked fields' do
        user = Object.new
        user.extend RailsJwtAuth::Trackable

        allow(RailsJwtAuth::JwtManager).to receive(:decode).and_return([{}])
        allow(RailsJwtAuth.model).to receive(:get_by_token).and_return(user)

        expect(user).to receive(:update_tracked_fields!).and_return(true)
        helper.authenticate
      end
    end
  end

  describe '#unauthorize!' do
    it 'throws NotAuthorized exception' do
      expect { helper.unauthorize! }.to raise_error(RailsJwtAuth::NotAuthorized)
    end
  end

  describe '#signed_in?' do
    it 'returns if there is current user' do
      expect(helper.signed_in?).to be_falsey
      @current_user = Object.new
      expect(helper.signed_in?).to be_truthy
    end
  end
end
