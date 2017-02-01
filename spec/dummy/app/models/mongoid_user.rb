class MongoidUser
  include Mongoid::Document
  include RailsJwtAuth::Authenticatable
end
