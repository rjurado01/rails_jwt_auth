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
      session = user.create_session
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
  end
end
