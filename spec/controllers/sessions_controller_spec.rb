require 'rails_helper'

describe SessionsController do
  it "prueba" do
    post :create, {}
    p response.status
  end
end
