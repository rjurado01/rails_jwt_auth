module RailsJwtAuth
  class Session
    include RailsJwtAuth::SessionHelper

    attr_reader :user, :errors, :jwt

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
  end
end
