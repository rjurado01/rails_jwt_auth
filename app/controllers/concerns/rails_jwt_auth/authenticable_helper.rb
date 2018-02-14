module RailsJwtAuth
  module AuthenticableHelper
    RailsJwtAuth::NotAuthorized = Class.new(StandardError)

    def current_user
      @current_user
    end

    def signed_in?
      !current_user.nil?
    end

    def authenticate!
      unauthorize! unless request.env['HTTP_AUTHORIZATION']
      token = request.env['HTTP_AUTHORIZATION'].split.last

      begin
        payload = JwtManager.decode(token).first.with_indifferent_access
        unauthorize! unless JwtManager.valid_payload?(payload)

        @current_user = RailsJwtAuth.model.from_token_payload(payload)
      rescue
        unauthorize!
      end
    end

    def unauthorize!
      raise NotAuthorized
    end
  end
end
