FactoryGirl.define do
  factory :mongoid_user, class: MongoidUser do
    email
    password '12345678'

    before :create do |user|
      user.skip_confirmation!
    end
  end

  factory :mongoid_unconfirmed_user, class: MongoidUser do
    email
    password '12345678'
  end
end
