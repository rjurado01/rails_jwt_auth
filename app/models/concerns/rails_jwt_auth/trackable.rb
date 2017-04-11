module RailsJwtAuth
  module Trackable
    def update_tracked_fields!(request)
      self.last_sign_in_at = Time.now.utc
      self.last_sign_in_ip = request.respond_to?(:remote_ip) ? request.remote_ip : request.ip
      save(validate: false)
    end

    def self.included(base)
      if defined?(Mongoid) && base.ancestors.include?(Mongoid::Document)
        base.send(:field, :last_sign_in_at, type: Time)
        base.send(:field, :last_sign_in_ip, type: String)
      end
    end
  end
end
