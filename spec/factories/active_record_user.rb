FactoryGirl.define do
  factory :active_record_user, class: ActiveRecordUser do
    email
    password '12345678'

    before :create do |user|
      user.skip_confirmation!
    end
  end

  factory :active_record_unconfirmed_user, class: ActiveRecordUser do
    email
    password '12345678'
  end
end
