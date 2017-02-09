module RailsJwtAuth
  class JwtRequest
    def initialize(request)
      return unless (@jwt = request.env['HTTP_AUTHORIZATION'])
      @jwt_info = RailsJwtAuth::JwtManager.decode(@jwt)
    end

    def valid?
      @jwt && RailsJwtAuth::JwtManager.valid_payload?(payload)
    end

    def payload
      @jwt_info ? @jwt_info[0] : nil
    end

    def header
      @jwt_info ? @jwt_info[1] : nil
    end

    def auth_token
      payload ? payload['auth_token'] : nil
    end
  end
end
