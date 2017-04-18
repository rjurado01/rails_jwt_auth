require 'rails_helper'
require 'rails_jwt_auth/strategies/jwt'
require 'rails_jwt_auth/jwt/manager'

describe RailsJwtAuth::Strategies::Jwt do
  describe '.authenticate!' do
    before :all do
      RailsJwtAuth.model_name = ActiveRecordUser.to_s
      RailsJwtAuth.simultaneous_sessions = 1
    end

    let(:user) { FactoryGirl.create(:active_record_user) }

    context 'when jwt is valid' do
      it 'success!' do
        token = user.regenerate_auth_token
        jwt = RailsJwtAuth::Jwt::Manager.encode(auth_token: token)
        env = {'HTTP_AUTHORIZATION' => "Bearer #{jwt}"}

        strategy = RailsJwtAuth::Strategies::Jwt.new(env)
        expect(strategy).to receive('success!')
        strategy.authenticate!
      end
    end

    context 'when jwt is invalid' do
      after do
        RailsJwtAuth.jwt_issuer = 'RailsJwtAuth'
      end

      it 'fail!' do
        token = user.regenerate_auth_token
        jwt = RailsJwtAuth::Jwt::Manager.encode(auth_token: token)
        env = {'HTTP_AUTHORIZATION' => "Bearer #{jwt}"}

        strategy = RailsJwtAuth::Strategies::Jwt.new(env)
        expect(strategy).to receive('fail!')
        RailsJwtAuth.jwt_issuer = 'invalid'
        strategy.authenticate!
      end
    end

    context 'when jwt is expired' do
      after do
        RailsJwtAuth.jwt_expiration_time = 7.days
      end

      it 'fail!' do
        RailsJwtAuth.jwt_expiration_time = 1.second
        token = user.regenerate_auth_token
        jwt = RailsJwtAuth::Jwt::Manager.encode(auth_token: token)
        env = {'HTTP_AUTHORIZATION' => "Bearer #{jwt}"}
        sleep 2

        strategy = RailsJwtAuth::Strategies::Jwt.new(env)
        expect(strategy).to receive('fail!')
        strategy.authenticate!
      end
    end

    context 'when user remove auth_token' do
      it 'fail!' do
        token = user.regenerate_auth_token
        jwt = RailsJwtAuth::Jwt::Manager.encode(auth_token: token)
        env = {'HTTP_AUTHORIZATION' => "Bearer #{jwt}"}

        strategy = RailsJwtAuth::Strategies::Jwt.new(env)
        expect(strategy).to receive('fail!')
        user.regenerate_auth_token
        strategy.authenticate!
      end
    end
  end
end
