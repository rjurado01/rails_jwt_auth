require 'jwt'

module RailsJwtAuth
  module JwtManager
    def self.secret_key_base
      Rails.application.secrets.secret_key_base || Rails.application.credentials.secret_key_base
    end

    # Encodes and signs JWT Payload with expiration
    def self.encode(payload)
      payload.reverse_merge!(meta)
      JWT.encode(payload, secret_key_base)
    end

    # Decodes the JWT with the signed secret
    # [{"auth_token"=>"xxx", "exp"=>148..., "iss"=>"RJA"}, {"typ"=>"JWT", "alg"=>"HS256"}]
    def self.decode(token)
      JWT.decode(token, secret_key_base)
    end

    # Default options to be encoded in the token
    def self.meta
      {
        exp: RailsJwtAuth.jwt_expiration_time.from_now.to_i,
        iss: RailsJwtAuth.jwt_issuer
      }
    end
  end
end
