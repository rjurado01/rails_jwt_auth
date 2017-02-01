class MongoidUser
  include Mongoid::Document
  include RailsTokenAuth::Authenticatable
end
