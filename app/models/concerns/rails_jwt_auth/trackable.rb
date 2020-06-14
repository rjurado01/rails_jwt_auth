module RailsJwtAuth
  module Trackable
    def track_session_info(request)
      return unless request

      self.last_sign_in_at = Time.current
      self.last_sign_in_ip = request.respond_to?(:remote_ip) ? request.remote_ip : request.ip
    end

    def update_tracked_request_info(request)
      return unless request

      self.last_request_at = Time.current
      self.last_request_ip = request.respond_to?(:remote_ip) ? request.remote_ip : request.ip
      self.save(validate: false)
    end

    def self.included(base)
      base.class_eval do
        if defined?(Mongoid) && ancestors.include?(Mongoid::Document)
          field :last_sign_in_at, type: Time
          field :last_sign_in_ip, type: String
          field :last_request_at, type: Time
          field :last_request_ip, type: String
        end
      end
    end
  end
end
