include ActiveModel::SecurePassword

module RailsJwtAuth
  module Authenticatable
    def self.included(base)
      base.extend(ClassMethods)

      base.class_eval do
        if defined?(Mongoid) && ancestors.include?(Mongoid::Document)
          field :password_digest, type: String
          field :auth_tokens, type: Array if RailsJwtAuth.simultaneous_sessions > 0
        elsif defined?(ActiveRecord) && ancestors.include?(ActiveRecord::Base)
          serialize :auth_tokens, Array
        end

        has_secure_password

        before_update do
          if RailsJwtAuth.send_password_changed_notification &&
             password_digest_changed? && password_digest_was
            RailsJwtAuth.send_email(RailsJwtAuth.mailer.password_changed(self))
          end
        end
      end
    end

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
      current_password_error = if (current_password = params.delete(:current_password)).blank?
                                 'blank'
                               elsif !authenticate(current_password)
                                 'invalid'
                               end

      # if recoberable module is enabled ensure clean recovery to allow save
      if self.respond_to? :reset_password_token
        self.reset_password_token = self.reset_password_sent_at = nil
      end

      assign_attributes(params)
      valid? # validates first other fields
      errors.add(:current_password, current_password_error) if current_password_error
      errors.add(:password, 'blank') if params[:password].blank?

      errors.empty? ? save : false
    end

    def to_token_payload(_request=nil)
      if RailsJwtAuth.simultaneous_sessions > 0
        {auth_token: regenerate_auth_token}
      else
        {id: id.to_s}
      end
    end

    def save_without_password
      valid?
      errors.delete(:password) # allow register without pass
      return false unless errors.empty?

      save(validate: false)
    end

    module ClassMethods
      def from_token_payload(payload)
        if RailsJwtAuth.simultaneous_sessions > 0
          get_by_token(payload['auth_token'])
        else
          where(id: payload['id']).first
        end
      end

      def get_by_token(token)
        if defined?(Mongoid) && ancestors.include?(Mongoid::Document)
          where(auth_tokens: token).first
        elsif defined?(ActiveRecord) && ancestors.include?(ActiveRecord::Base)
          where('auth_tokens like ?', "%#{token}%").first
        end
      end
    end
  end
end
