module RailsJwtAuth
  class OmniAuthSession
    attr_reader :user, :errors, :jwt

    Errors = Struct.new :details # simulate ActiveModel::Errors

    def initialize(strategy_class, params={})
      @strategy_class = strategy_class
      @params = params
    end

    def generate!(request)
      x = @strategy_class.new(Rails.application.routes, @params)
      x.options['redirect_uri'] = 'postmessage'
      x.instance_variable_set('@env', request.env)
      x.instance_variable_set('@request', request)
      x.instance_variable_set('@access_token', x.build_access_token)

      @user = RailsJwtAuth.model_name.constantize.from_omniauth(
        @strategy_class.name.demodulize.underscore,
        x.raw_info
      )

      if valid?
        @user.track_session_info(request) if trackable?
        @user.load_auth_token

        unless user.save
          add_error(RailsJwtAuth.model_name.underscore, :invalid)

          return false
        end

        generate_jwt(request)

        true
      else
        false
      end
    end

    def valid?
      validate!

      !errors?
    end

    def validate!
      # Can't use ActiveModel::Validations since we have dynamic fields
      @errors = Errors.new({})

      validate_user_exist
      validate_custom
    end

    private

    def trackable?
      @user&.kind_of?(RailsJwtAuth::Trackable)
    end

    def validate_user_exist
      add_error(:session, :invalid) unless @user
    end

    def validate_custom
      # allow add custom validations overwriting this method
    end

    def add_error(field, detail)
      @errors.details[field.to_sym] ||= []
      @errors.details[field.to_sym].push({error: detail})
    end

    def errors?
      @errors.details.any?
    end

    def generate_jwt(request)
      @jwt = JwtManager.encode(user.to_token_payload(request))
    end
  end
end
