module RailsJwtAuth
  class Session
    attr_reader :user, :errors, :jwt

    Errors = Struct.new :details # simulate ActiveModel::Errors

    def initialize(params={})
      @auth_field_value = params[RailsJwtAuth.auth_field_name]
      @password = params[:password]

      find_user if @auth_field_value.present?
    end

    def valid?
      validate!

      @errors.details.empty?
    end

    def generate!(request)
      if valid?
        user.unlock_access! if lockable?
        generate_jwt(request)

        true
      else
        user.failed_attempt! if lockable?

        false
      end
    end

    private

    # Can't use ActiveModel::Validations since we have dynamic fields
    def validate!
      @errors = Errors.new({})

      validate_auth_field_presence
      validate_password_presence
      validate_user_exist
      validate_user_password if user?
      validate_user_is_confirmed if confirmable?
      validate_user_is_not_locked if lockable?
      validate_custom
    end

    def find_user
      @user = RailsJwtAuth.model.where(RailsJwtAuth.auth_field_name => @auth_field_value).first
    end

    def confirmable?
      @user&.kind_of?(RailsJwtAuth::Confirmable)
    end

    def lockable?
      @user&.kind_of?(RailsJwtAuth::Lockable)
    end

    def user?
      @user.present?
    end

    def field_error(field)
      RailsJwtAuth.email_error ? field : :session
    end

    def validate_auth_field_presence
      add_error(RailsJwtAuth.auth_field_name, :blank) unless @auth_field_value
    end

    def validate_password_presence
      add_error(:password, :blank) if @password.blank?
    end

    def validate_user_exist
      add_error(field_error(RailsJwtAuth.auth_field_name), :invalid) unless @user
    end

    def validate_user_password
      add_error(field_error(:password), :invalid) unless @user.authenticate(@password)
    end

    def validate_custom
      # allow add custom validation overwriting this method
    end

    def validate_user_is_confirmed
      add_error(RailsJwtAuth.email_field_name, :unconfirmed) unless @user.confirmed?
    end

    def validate_user_is_not_locked
      add_error(RailsJwtAuth.email_field_name, :locked) if @user.access_locked?
    end

    def validate_custom
      # allow add custom validations overwriting this method
    end

    def add_error(field, detail)
      @errors.details[field.to_sym] ||= []
      @errors.details[field.to_sym].push({error: detail})
    end

    def generate_jwt(request)
      @jwt = JwtManager.encode(user.to_token_payload(request))
    end
  end
end
