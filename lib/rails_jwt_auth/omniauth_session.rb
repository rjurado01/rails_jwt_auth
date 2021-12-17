module RailsJwtAuth
  class OmniauthSession
    include RailsJwtAuth::SessionHelper

    attr_reader :user, :errors, :jwt

    def initialize(user)
      @user = user
    end

    def valid?
      validate!

      !errors?
    end

    def generate!
      if valid?
        @user.clean_reset_password if recoverable?
        @user.clean_lock if lockable?
        @user.load_auth_token

        unless user.save
          add_error(RailsJwtAuth.model_name.underscore, :invalid)

          return false
        end

        generate_jwt(nil)

        true
      else
        @user.failed_attempt if lockable?

        false
      end
    end

    private

    def validate!
      # Can't use ActiveModel::Validations since we have dynamic fields
      @errors = Errors.new({})

      validate_user
      validate_user_is_confirmed if confirmable?
      validate_user_is_not_locked if lockable?
      validate_custom
    end
  end
end
