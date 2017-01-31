include ActiveModel::SecurePassword

module RailsTokenAuth
  module Authenticatable
    def regenerate_auth_token(token=nil)
      if RTA.simultaneous_sessions > 1
        tokens = ((self.auth_tokens || []) - [token]).last(RTA.simultaneous_sessions)
        self.update_attribute(:auth_tokens, (tokens + [SecureRandom.base58(24)]).uniq)
      else
        self.update_attribute(:auth_tokens, [SecureRandom.base58(24)])
      end
    end

    def destroy_auth_token(token)
      if RTA.simultaneous_sessions > 1
        tokens = self.auth_tokens || []
        self.update_attribute(:auth_tokens, tokens - [token])
      else
        self.update_attribute(:auth_tokens, [])
      end
    end

    module ClassMethods
      def get_by_token(token)
        if defined? Mongoid
          RTA.model.where(auth_tokens: token).first
        else
          RTA.model.where("auth_tokens like ?", "% #{token}\n%").first
        end
      end
    end

    def self.included(base)
      if defined? Mongoid
        base.send(:field, RTA.auth_field_name,  {type: String})
        base.send(:field, :password_digest,     {type: String})
        base.send(:field, :auth_tokens,         {type: Array})
      else
        base.send(:serialize, :auth_tokens, Array)
      end

      base.send(:validates, RTA.auth_field_name, {presence: true, uniqueness: true})
      base.send(:validates, RTA.auth_field_name, {email: true}) if RTA.auth_field_email

      base.send(:has_secure_password)

      base.extend(ClassMethods)
    end
  end
end
