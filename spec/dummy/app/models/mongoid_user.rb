class MongoidUser
  include Mongoid::Document
  include RailsJwtAuth::Authenticatable
  include RailsJwtAuth::Confirmable
  include RailsJwtAuth::Recoverable
end
