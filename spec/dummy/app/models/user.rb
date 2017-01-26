class User
  include Mongoid::Document
  include Mongoid::AuthModel
  include Mongoid::Timestamps
end
