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

  describe '#valid?' do
    context 'when all is valid' do
      it 'returns true' do
        token = user.regenerate_auth_token
        jwt = RailsJwtAuth::Jwt::Manager.encode(auth_token: token)
        request = Request.new('HTTP_AUTHORIZATION' => "Bearer #{jwt}")

        jwt_request = RailsJwtAuth::Jwt::Request.new(request)
        expect(jwt_request.valid?).to be_truthy
      end
    end

    context 'when token is invalid' do
      after do
        RailsJwtAuth.jwt_issuer = 'RailsJwtAuth'
      end

      it 'returns false' do
        token = user.regenerate_auth_token
        jwt = RailsJwtAuth::Jwt::Manager.encode(auth_token: token)
        request = Request.new('HTTP_AUTHORIZATION' => "Bearer #{jwt}")

        RailsJwtAuth.jwt_issuer = 'invalid'
        jwt_request = RailsJwtAuth::Jwt::Request.new(request)
        expect(jwt_request.valid?).to be_falsey
      end
    end

    context 'when token is expired' do
      after do
        RailsJwtAuth.jwt_expiration_time = 7.days
      end

      it 'returns false' do
        RailsJwtAuth.jwt_expiration_time = 1.second
        token = user.regenerate_auth_token
        jwt = RailsJwtAuth::Jwt::Manager.encode(auth_token: token)
        request = Request.new('HTTP_AUTHORIZATION' => "Bearer #{jwt}")
        sleep 2

        jwt_request = RailsJwtAuth::Jwt::Request.new(request)
        expect(jwt_request.valid?).to be_falsey
      end
    end

    context 'when verification fails' do
      after do
        RailsJwtAuth.jwt_expiration_time = 7.days
      end

      it 'returns false' do
        invalid = "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJhdXRoX3Rva2VuIjoiZXc2bkN5RGZxQ3k5dEhzc2lCQUFmVVF0IiwiZXhwIjoxNDk5MDk4MTM0LCJpc3MiOiJSYWlsc0p3dEF1dGgifQ.V46G2lOT8CmzCGvToMfCAhB5C0t6eOa7XDO0J5eKsvL"
        request = Request.new('HTTP_AUTHORIZATION' => "Bearer #{invalid}")

        RailsJwtAuth.jwt_issuer = 'new_issuer'
        jwt_request = RailsJwtAuth::Jwt::Request.new(request)
        expect(jwt_request.valid?).to be_falsey
      end
    end

    context 'when user does not exist' do
      after do
        RailsJwtAuth.jwt_issuer = 'RailsJwtAuth'
      end

      it 'returns false' do
        jwt = RailsJwtAuth::Jwt::Manager.encode(auth_token: 'xxxxyyyyzzzz')
        request = Request.new('HTTP_AUTHORIZATION' => "Bearer #{jwt}")

        RailsJwtAuth.jwt_issuer = 'invalid'
        jwt_request = RailsJwtAuth::Jwt::Request.new(request)
        expect(jwt_request.valid?).to be_falsey
      end
    end
  end

  describe '#payload' do
    it 'returns jwt payload' do
      token = user.regenerate_auth_token
      jwt = RailsJwtAuth::Jwt::Manager.encode(auth_token: token)
      request = Request.new('HTTP_AUTHORIZATION' => "Bearer #{jwt}")

      jwt_request = RailsJwtAuth::Jwt::Request.new(request)
      expect(jwt_request.payload['iss']).to eq(RailsJwtAuth.jwt_issuer)
      expect(user.auth_tokens).to include(jwt_request.payload['auth_token'])
      expect(jwt_request.payload['exp']).not_to be_nil
    end
  end

  describe '#header' do
    it 'returns jwt header' do
      token = user.regenerate_auth_token
      jwt = RailsJwtAuth::Jwt::Manager.encode(auth_token: token)
      request = Request.new('HTTP_AUTHORIZATION' => "Bearer #{jwt}")

      jwt_request = RailsJwtAuth::Jwt::Request.new(request)
      expect(jwt_request.header).to eq('typ' => 'JWT', 'alg' => 'HS256')
    end
  end

  describe '#auth_token' do
    it 'returns jwt payload auth_token' do
      token = user.regenerate_auth_token
      jwt = RailsJwtAuth::Jwt::Manager.encode(auth_token: token)
      request = Request.new('HTTP_AUTHORIZATION' => "Bearer #{jwt}")

      jwt_request = RailsJwtAuth::Jwt::Request.new(request)
      expect(user.auth_tokens).to include(jwt_request.auth_token)
    end
  end
end
