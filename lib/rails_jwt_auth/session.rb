module RailsJwtAuth
  class Session
    attr_reader :user, :errors, :jwt

    Errors = Struct.new :details # simulate ActiveModel::Errors

    def initialize(params={})
      @auth_field_value = (params[RailsJwtAuth.auth_field_name] || '').strip
      @auth_field_value.downcase! if RailsJwtAuth.downcase_auth_field
      @password = params[:password]

      find_user if @auth_field_value.present?
    end

    def valid?
      validate!

      !errors?
    end

    def generate!(request)
      if valid?
        user.clean_reset_password if recoverable?
        user.clean_lock if lockable?
        user.track_session_info(request) if trackable?
        user.load_auth_token

        unless user.save
          add_error(RailsJwtAuth.model_name.underscore, :invalid)

          return false
        end

        generate_jwt(request)

        true
      else
        user.failed_attempt if lockable?

        false
      end
    end

    private

    def validate!
      # Can't use ActiveModel::Validations since we have dynamic fields
      @errors = Errors.new({})

      validate_auth_field_presence
      validate_password_presence
      validate_user_exist
      validate_user_is_confirmed if confirmable?
      validate_user_is_not_locked if lockable?
      validate_user_password unless errors?
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

    def recoverable?
      @user&.kind_of?(RailsJwtAuth::Recoverable)
    end

    def trackable?
      @user&.kind_of?(RailsJwtAuth::Trackable)
    end

    def user?
      @user.present?
    end

    def field_error(field)
      RailsJwtAuth.avoid_email_errors ? :session : field
    end

    def validate_auth_field_presence
      add_error(RailsJwtAuth.auth_field_name, :blank) if @auth_field_value.blank?
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

    def errors?
      @errors.details.any?
    end

    def generate_jwt(request)
      @jwt = JwtManager.encode(user.to_token_payload(request))
    end
  end
end
