module RailsJwtAuth
  module WardenHelper
    def signed_in?
      !current_user.nil?
    end

    def current_user
      warden.user
    end

    def warden
      request.env['warden']
    end

    def authenticate!
      warden.authenticate!
    end

    def self.included(base)
      return unless Rails.env.test? && base.name == 'ApplicationController'

      base.send(:rescue_from, RailsJwtAuth::Spec::NotAuthorized) do
        render json: {}, status: 401
      end
    end
  end
end
