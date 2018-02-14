include ActiveModel::SecurePassword

module RailsJwtAuth
  module Authenticatable
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

    def to_token_payload(_request=nil)
      {sub: id.to_s}
    end

    module ClassMethods
      def from_token_payload(payload)
        find payload[:sub]
      end
    end

    def self.included(base)
      base.extend(ClassMethods)

      base.class_eval do
        if defined?(Mongoid) && ancestors.include?(Mongoid::Document)
          field RailsJwtAuth.auth_field_name, type: String
          field :password_digest,             type: String
        end

        validates RailsJwtAuth.auth_field_name, presence: true, uniqueness: true
        validates RailsJwtAuth.auth_field_name, email: true if RailsJwtAuth.auth_field_email

        has_secure_password

        before_validation do
          auth_field = RailsJwtAuth.auth_field_name
          self[auth_field] = self[auth_field].downcase if self[auth_field]
        end
      end
    end
  end
end
