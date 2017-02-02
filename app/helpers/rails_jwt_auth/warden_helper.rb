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
  end
end
