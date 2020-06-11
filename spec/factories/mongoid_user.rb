FactoryBot.define do
  factory :mongoid_unconfirmed_user, class: MongoidUser do
    email
    password '12345678'
    sequence(:username) { |n| "user_#{n}" }
  end

  factory :mongoid_user, parent: :mongoid_unconfirmed_user do
    before :create do |user|
      user.skip_confirmation
    end
  end

  factory :mongoid_user_without_password, class: MongoidUser do
    email
    sequence(:username) { |n| "user_#{n}" }
  end
end
