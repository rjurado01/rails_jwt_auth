require 'rails_helper'

describe RailsJwtAuth::Jwt::Request do
  let(:user) { FactoryGirl.create(:active_record_user) }

  before :all do
    class Request
      def initialize(env)
        @env = env
      end

      def env
        @env
      end
    end
  end

  after :all do
    Object.send(:remove_const, :Request)
  end

  let(:jwt) do
    session = user.create_session
    RailsJwtAuth::Jwt::Manager.encode(session_id: session[:id])
  end

  let(:request) do
    Request.new('HTTP_AUTHORIZATION' => "Bearer #{jwt}")
  end

  describe '#valid?' do
    context 'when all is valid' do
      it 'returns true' do
        jwt_request = RailsJwtAuth::Jwt::Request.new(request)
        expect(jwt_request.valid?).to be_truthy
      end
    end

    context 'when iss is invalid' do
      after do
        RailsJwtAuth.jwt_issuer = 'RailsJwtAuth'
      end

      it 'returns false' do
        jwt_request = RailsJwtAuth::Jwt::Request.new(request)
        RailsJwtAuth.jwt_issuer = 'new_issuer'
        expect(jwt_request.valid?).to be_falsey
      end
    end

    context 'when session is expired' do
      after do
        RailsJwtAuth.jwt_expiration_time = 7.days
      end

      it 'returns false' do
        RailsJwtAuth.jwt_expiration_time = 1.day
        jwt

        Timecop.freeze(Date.today + 2) do
          jwt_request = RailsJwtAuth::Jwt::Request.new(request)
          expect(jwt_request.valid?).to be_falsey
        end
      end
    end

    context 'when verification fails' do
      it 'returns false' do
        invalid = 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJhdXRoX3Rva2VuIjoiZXc2bkN5RGZxQ3k5dEhzc2lCQUFmVVF0IiwiZXhwIjoxNDk5MDk4MTM0LCJpc3MiOiJSYWlsc0p3dEF1dGgifQ.V46G2lOT8CmzCGvToMfCAhB5C0t6eOa7XDO0J5eKsvL'
        request = Request.new('HTTP_AUTHORIZATION' => "Bearer #{invalid}")
        jwt_request = RailsJwtAuth::Jwt::Request.new(request)
        expect(jwt_request.valid?).to be_falsey
      end
    end
  end

  describe '#payload' do
    it 'returns jwt payload' do
      jwt_request = RailsJwtAuth::Jwt::Request.new(request)
      expect(jwt_request.payload['iss']).to eq(RailsJwtAuth.jwt_issuer)
      expect(user.sessions.last[:id]).to eq(jwt_request.payload['session_id'])
      expect(jwt_request.payload['exp']).not_to be_nil
    end
  end

  describe '#header' do
    it 'returns jwt header' do
      jwt_request = RailsJwtAuth::Jwt::Request.new(request)
      expect(jwt_request.header).to eq('typ' => 'JWT', 'alg' => 'HS256')
    end
  end

  describe '#session_id' do
    it 'returns jwt payload auth_token' do
      jwt_request = RailsJwtAuth::Jwt::Request.new(request)
      expect(user.sessions.last[:id]).to eq(jwt_request.session_id)
    end
  end
end
