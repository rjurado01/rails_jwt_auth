require 'rails_jwt_auth/jwt/manager'

module RailsJwtAuth
  module Jwt
    class Request
      def initialize(request)
        return unless request.env['HTTP_AUTHORIZATION']
        @jwt = request.env['HTTP_AUTHORIZATION'].split.last

        begin
          @jwt_info = RailsJwtAuth::Jwt::Manager.decode(@jwt)
        rescue JWT::ExpiredSignature
          @jwt_info = false
        end
      end

      def valid?
        @jwt && @jwt_info && RailsJwtAuth::Jwt::Manager.valid_payload?(payload)
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
end
