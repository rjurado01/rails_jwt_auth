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

    let(:jwt) do
      session = user.create_session(user_agent: 'USER_AGENT', ip: '127.0.0.1')
      RailsJwtAuth::Jwt::Manager.encode(session_id: session[:id])
    end

    let(:env) do
      {'HTTP_AUTHORIZATION' => "Bearer #{jwt}"}
    end

    context 'when jwt is valid' do
      it 'success!' do
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
        strategy = RailsJwtAuth::Strategies::Jwt.new(env)
        expect(strategy).to receive('fail!')
        RailsJwtAuth.jwt_issuer = 'new_issuer'
        strategy.authenticate!
      end
    end

    context 'when jwt is expired' do
      after do
        RailsJwtAuth.jwt_expiration_time = 7.days
      end

      it 'fail!' do
        RailsJwtAuth.jwt_expiration_time = 1.day
        jwt

        Timecop.freeze(Date.today + 2) do
          strategy = RailsJwtAuth::Strategies::Jwt.new(env)
          expect(strategy).to receive('fail!')
          strategy.authenticate!
        end
      end
    end

    context 'when user remove session' do
      it 'fail!' do
        strategy = RailsJwtAuth::Strategies::Jwt.new(env)
        expect(strategy).to receive('fail!')
        user.destroy_session(user.sessions.last[:id])
        strategy.authenticate!
      end
    end

    context 'when user_agent validation is enabled' do
      before(:all) { RailsJwtAuth.validate_user_agent = true }
      after(:all) { RailsJwtAuth.validate_user_agent = false }

      context 'when user_agent is valid' do
        it 'success!' do
          custom_env = env.merge('HTTP_USER_AGENT' => 'USER_AGENT')
          strategy = RailsJwtAuth::Strategies::Jwt.new(custom_env)
          expect(strategy).to receive('success!')
          strategy.authenticate!
        end
      end

      context 'when user_agent is invalid' do
        it 'fail!' do
          custom_env = env.merge('HTTP_USER_AGENT' => 'invalid')
          strategy = RailsJwtAuth::Strategies::Jwt.new(custom_env)
          expect(strategy).to receive('fail!')
          strategy.authenticate!
        end
      end
    end

    context 'when ip validation is enabled' do
      before(:all) { RailsJwtAuth.validate_ip = true }
      after(:all) { RailsJwtAuth.validate_ip = false }

      context 'when ip is valid' do
        it 'success!' do
          custom_env = env.merge('REMOTE_ADDR' => '127.0.0.1')
          strategy = RailsJwtAuth::Strategies::Jwt.new(custom_env)
          expect(strategy).to receive('success!')
          strategy.authenticate!
        end
      end

      context 'when ip is invalid' do
        it 'fail!' do
          custom_env = env.merge('REMOTE_ADDR' => 'invalid')
          strategy = RailsJwtAuth::Strategies::Jwt.new(custom_env)
          expect(strategy).to receive('fail!')
          strategy.authenticate!
        end
      end
    end
  end
end
