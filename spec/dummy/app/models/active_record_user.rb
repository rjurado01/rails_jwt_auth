class ActiveRecordUser < ApplicationRecord
  include RailsTokenAuth::Authenticatable
end
