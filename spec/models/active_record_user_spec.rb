require 'rails_helper'

describe ActiveRecordUser do
  it "has authenticate method" do
    ActiveRecordUser.destroy_all
    user = ActiveRecordUser.create(email: "user@email.com", password: "12345678")
    expect(ActiveRecordUser.count).to eq(1)
    expect(user.authenticate("12345678")).not_to eq(false)
    expect(user.authenticate("invalid")).to eq(false)
  end
end
