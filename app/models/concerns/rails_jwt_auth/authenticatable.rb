include ActiveModel::SecurePassword

module RailsJwtAuth
  module Authenticatable
    def create_session(info={})
      new_session = {id: SecureRandom.base58(24), created_at: Time.now.to_i}.merge(info)
      self.sessions = ((sessions || []) + [new_session]).last(RailsJwtAuth.simultaneous_sessions)
      save ? new_session : false
    end

    def destroy_session(session_id)
      return false unless sessions
      self.sessions = sessions.reject { |session| session[:id] == session_id }
      save
    end

    def update_with_password(params)
      if (current_password = params.delete(:current_password)).blank?
        errors.add(:current_password, I18n.t('rails_jwt_auth.errors.current_password.blank'))
      elsif !authenticate(current_password)
        errors.add(:current_password, I18n.t('rails_jwt_auth.errors.current_password.invalid'))
      end

      if params[:password].blank?
        errors.add(:password, I18n.t('rails_jwt_auth.errors.password.blank'))
      end

      errors.empty? ? update_attributes(params) : false
    end

    module ClassMethods
      def get_by_session_id(id)
        if defined?(Mongoid) && ancestors.include?(Mongoid::Document)
          where('sessions.id' => id).first
        elsif defined?(ActiveRecord) && ancestors.include?(ActiveRecord::Base)
          where('sessions like ?', "%id: #{id}%").first
        end
      end
    end

    def self.included(base)
      base.extend(ClassMethods)

      base.class_eval do
        if defined?(Mongoid) && ancestors.include?(Mongoid::Document)
          field RailsJwtAuth.auth_field_name, type: String
          field :password_digest,             type: String
          field :sessions,                    type: Array
        elsif defined?(ActiveRecord) && ancestors.include?(ActiveRecord::Base)
          serialize :sessions, Array
        end

        validates RailsJwtAuth.auth_field_name, presence: true, uniqueness: true
        validates RailsJwtAuth.auth_field_name, email: true if RailsJwtAuth.auth_field_email

        has_secure_password

        before_validation do
          self.email = email.downcase if email
        end
      end
    end
  end
end
