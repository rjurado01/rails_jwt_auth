module RailsJwtAuth
  module Trackable
    def update_tracked_fields!(request)
      self.last_sign_in_at = Time.current
      self.last_sign_in_ip = request.respond_to?(:remote_ip) ? request.remote_ip : request.ip
      save(validate: false)
    end

    def self.included(base)
      base.class_eval do
        if defined?(Mongoid) && ancestors.include?(Mongoid::Document)
          field :last_sign_in_at, type: Time
          field :last_sign_in_ip, type: String
        end
      end
    end
  end
end
