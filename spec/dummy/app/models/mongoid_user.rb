class MongoidUser
  include Mongoid::Document
  include RailsJwtAuth::Authenticatable
  include RailsJwtAuth::Confirmable
  include RailsJwtAuth::Recoverable
  include RailsJwtAuth::Trackable
  include RailsJwtAuth::Invitable

  field :name, type: String # For invitable
end
