include ActiveModel::SecurePassword

module RailsTokenAuth
  module Authenticatable
    def regenerate_auth_token
      self.update_attribute(:auth_token, SecureRandom.base58(24))
    end

    def destroy_auth_token
      self.update_attribute(:auth_token, nil)
    end

    def self.included(base)
      if defined? Mongoid
        base.send(:field, :email,           {type: String})
        base.send(:field, :password_digest, {type: String})
        base.send(:field, :auth_token,      {type: String})
      end

      base.send(:validates, :email, {presence: true, uniqueness: true, email: true})

      base.send(:has_secure_password)
    end
  end
end
