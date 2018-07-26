require 'rails_jwt_auth/jwt_manager'

module RailsJwtAuth
  NotAuthorized = Class.new(StandardError)

  module AuthenticableHelper
    def current_user
      @current_user
    end

    def signed_in?
      !current_user.nil?
    end

    def authenticate!
      begin
        payload = RailsJwtAuth::JwtManager.decode_from_request(request).first
      rescue JWT::ExpiredSignature, JWT::VerificationError, JWT::DecodeError
        unauthorize!
      end

      if !@current_user = RailsJwtAuth.model.from_token_payload(payload)
        unauthorize!
      elsif @current_user.respond_to? :update_tracked_fields!
        @current_user.update_tracked_fields!(request)
      end
    end

    def unauthorize!
      raise NotAuthorized
    end
  end
end
