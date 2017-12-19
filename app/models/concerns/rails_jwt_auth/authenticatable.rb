include ActiveModel::SecurePassword

module RailsJwtAuth
  module Authenticatable
    def regenerate_auth_token(token = nil)
      new_token = SecureRandom.base58(24)

      if RailsJwtAuth.simultaneous_sessions > 1
        tokens = ((auth_tokens || []) - [token]).last(RailsJwtAuth.simultaneous_sessions - 1)
        update_attribute(:auth_tokens, (tokens + [new_token]).uniq)
      else
        update_attribute(:auth_tokens, [new_token])
      end

      new_token
    end

    def destroy_auth_token(token)
      if RailsJwtAuth.simultaneous_sessions > 1
        tokens = auth_tokens || []
        update_attribute(:auth_tokens, tokens - [token])
      else
        update_attribute(:auth_tokens, [])
      end
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
      def get_by_token(token)
        if defined?(Mongoid) && ancestors.include?(Mongoid::Document)
          where(auth_tokens: token).first
        elsif defined?(ActiveRecord) && ancestors.include?(ActiveRecord::Base)
          where('auth_tokens like ?', "%#{token}%").first
        end
      end
    end

    def self.included(base)
      base.extend(ClassMethods)

      base.class_eval do
        if defined?(Mongoid) && ancestors.include?(Mongoid::Document)
          field RailsJwtAuth.auth_field_name, type: String
          field :password_digest,             type: String
          field :auth_tokens,                 type: Array
        elsif defined?(ActiveRecord) && ancestors.include?(ActiveRecord::Base)
          serialize :auth_tokens, Array
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
