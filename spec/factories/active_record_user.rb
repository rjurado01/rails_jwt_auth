FactoryBot.define do
  factory :active_record_user, class: ActiveRecordUser do
    email
    password '12345678'
    name 'FakeName' # For invitable

    before :create do |user|
      user.skip_confirmation!
    end
  end

  factory :active_record_unconfirmed_user, class: ActiveRecordUser do
    email
    password '12345678'
    name 'FakeName' # For invitable
  end
end
