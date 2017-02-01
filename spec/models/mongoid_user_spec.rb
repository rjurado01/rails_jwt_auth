require 'rails_helper'

describe MongoidUser do
  it "has authenticate method" do
    MongoidUser.destroy_all
    user = MongoidUser.create(email: "user@email.com", password: "12345678")
    expect(MongoidUser.count).to eq(1)
    expect(user.authenticate("12345678")).not_to eq(false)
    expect(user.authenticate("invalid")).to eq(false)
  end
end
