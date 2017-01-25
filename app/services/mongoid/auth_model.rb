include ActiveModel::SecurePassword

module Mongoid::AuthModel
  def self.included(base)
    base.send(:field, :email, {type: String})
    base.send(:field, :password_digest, {type: String})
    base.send(:field, :auth_token, {type: String})

    base.send(:has_secure_password)
  end
end
