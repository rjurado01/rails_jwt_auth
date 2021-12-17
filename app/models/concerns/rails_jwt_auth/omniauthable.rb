module RailsJwtAuth
  module Omniauthable
    class NotImplementedMethod < StandardError; end

    def self.included(klass)
      klass.extend(ClassMethods)
    end

    module ClassMethods
      def from_omniauth(_auth)
        raise NotImplementedMethod.new(
          I18n.t(
            'rails_jwt_auth.models.omniauthable.from_omniauth.not_implemented',
            model:RailsJwtAuth.model
          )
        )
      end
    end
  end
end
