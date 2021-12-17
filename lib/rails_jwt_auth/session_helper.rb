module RailsJwtAuth
	module SessionHelper
    Errors = Struct.new :details # simulate ActiveModel::Errors

		private

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

		def validate_user
      add_error(:session, :not_found) if @user.blank?
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
      @jwt = JwtManager.encode(@user.to_token_payload(request))
    end
	end
end