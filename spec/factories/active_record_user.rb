FactoryBot.define do
  factory :active_record_unconfirmed_user, class: ActiveRecordUser do
    email
    password '12345678'
    sequence(:username) { |n| "user_#{n}" }
  end

  factory :active_record_user, parent: :active_record_unconfirmed_user do
    before :create do |user|
      user.skip_confirmation
    end
  end

  factory :active_record_user_without_password, class: ActiveRecordUser do
    email
    sequence(:username) { |n| "user_#{n}" }
  end
end
