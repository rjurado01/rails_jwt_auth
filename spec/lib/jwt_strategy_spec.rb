require 'rails_helper'
require 'rails_jwt_auth/jwt_strategy'
require 'rails_jwt_auth/jwt_manager'

describe RailsJwtAuth::JwtStrategy do
  describe 'authenticate!' do
    before :all do
      RailsJwtAuth.model_name = ActiveRecordUser.to_s
      RailsJwtAuth.simultaneous_sessions = 1
      @user = ActiveRecordUser.create(email: 'user@emailc.com', password: '12345678')
    end

    context 'when jwt is valid' do
      it 'success' do
        token = @user.regenerate_auth_token
        jwt = RailsJwtAuth::JwtManager.encode(auth_token: token)
        env = {'HTTP_AUTHORIZATION' => jwt}

        strategy = RailsJwtAuth::JwtStrategy.new(env)
        expect(strategy).to receive('success!')
        strategy.authenticate!
      end
    end

    context 'when jwt is invalid' do
      after do
        RailsJwtAuth.jwt_issuer = 'RailsJwtAuth'
      end

      it 'fail' do
        token = @user.regenerate_auth_token
        jwt = RailsJwtAuth::JwtManager.encode(auth_token: token)
        env = {'HTTP_AUTHORIZATION' => jwt}

        strategy = RailsJwtAuth::JwtStrategy.new(env)
        expect(strategy).to receive('fail!')
        RailsJwtAuth.jwt_issuer = 'invalid'
        strategy.authenticate!
      end
    end

    context 'when user remove auth_token' do
      it 'fail' do
        token = @user.regenerate_auth_token
        jwt = RailsJwtAuth::JwtManager.encode(auth_token: token)
        env = {'HTTP_AUTHORIZATION' => jwt}

        strategy = RailsJwtAuth::JwtStrategy.new(env)
        expect(strategy).to receive('fail!')
        @user.regenerate_auth_token
        strategy.authenticate!
      end
    end
  end
end
