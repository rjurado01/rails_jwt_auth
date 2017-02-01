require 'rails_helper'

describe RailsTokenAuth::SessionsController do
  context "when use ActiveRecord model" do
    before :all do
      RTA.model_name = ActiveRecordUser.to_s

      ActiveRecordUser.destroy_all
      @user = ActiveRecordUser.create(email: "user@emailc.com", password: "12345678")
    end

    let(:json) { JSON.parse(response.body) }

    context "when parameters are invalid" do
      before do
        post :create, params: {}
      end

      it "returns 422 status code" do
        expect(response.status).to eq(422)
      end

      it "returns error message" do
        expect(json).to eq({"session"=>{"error"=>"Invalid email / password"}})
      end
    end

    context "when parameters are valid" do
      before do
        post :create, params: {email: @user.email, password: "12345678"}
      end

      it "returns 201 status code" do
        expect(response.status).to eq(201)
      end

      it "returns valid authentication token" do
        token = json["session"]["auth_token"]
        expect(JsonWebToken.decode(token)[0]["auth_token"]).to eq(@user.reload.auth_tokens.last)
      end
    end
  end

  context "when use Montoid model" do
    before :all do
      RTA.model_name = MongoidUser.to_s

      MongoidUser.destroy_all
      @user = MongoidUser.create(email: "user@emailc.com", password: "12345678")
    end

    let(:json) { JSON.parse(response.body) }

    context "when parameters are invalid" do
      before do
        post :create, params: {}
      end

      it "returns 422 status code" do
        expect(response.status).to eq(422)
      end

      it "returns error message" do
        expect(json).to eq({"session"=>{"error"=>"Invalid email / password"}})
      end
    end

    context "when parameters are valid" do
      before do
        post :create, params: {email: @user.email, password: "12345678"}
      end

      it "returns 201 status code" do
        expect(response.status).to eq(201)
      end

      it "returns valid authentication token" do
        token = json["session"]["auth_token"]
        expect(JsonWebToken.decode(token)[0]["auth_token"]).to eq(@user.reload.auth_tokens.last)
      end
    end
  end
end
