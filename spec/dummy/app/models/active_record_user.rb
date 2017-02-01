class ActiveRecordUser < ApplicationRecord
  include RailsJwtAuth::Authenticatable
end
