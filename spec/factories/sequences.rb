FactoryBot.define do
  sequence :email do |n|
    "user#{n}@email.com"
  end
end
