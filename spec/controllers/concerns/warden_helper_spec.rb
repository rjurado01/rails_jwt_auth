require 'rails_helper'

describe RailsJwtAuth::WardenHelper, type: :helper do
  context 'when user is not logged' do
    describe '#warden' do
      it "returns request.env['warden']" do
        expect(helper.warden).to be_nil
      end
    end

    describe '#current_user' do
      it 'returns warden user' do
        expect(helper.current_user).to be_nil
      end
    end

    describe 'signed_in?' do
      it 'returns if there is current user' do
        expect(helper.signed_in?).to be_falsey
      end
    end
  end

  context 'when user is logged' do
    class Proxy
      def user
        'user'
      end

      def authenticate!(options)
        true
      end
    end

    before do
      @proxy = Proxy.new
      helper.request.env['warden'] = @proxy
    end

    describe '#warden' do
      it "returns request.env['warden']" do
        expect(helper.warden).to eq(@proxy)
      end
    end

    describe '#current_user' do
      it 'returns warden user' do
        expect(helper.current_user).to eq(@proxy.user)
      end
    end

    describe '#authenticate!' do
      it 'calls warden authenticate method' do
        expect(@proxy).to receive(:authenticate!).with(store: false)
        helper.authenticate!
      end
    end

    describe 'signed_in?' do
      it 'returns if there is current user' do
        expect(helper.signed_in?).to be_truthy
        allow(@proxy).to receive(:user).and_return(nil)
        expect(helper.signed_in?).to be_falsey
      end
    end
  end
end
