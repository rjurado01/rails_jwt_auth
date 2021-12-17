require 'rails_helper'
require 'omniauth'

require 'rails_jwt_auth/session'

module RailsJwtAuth
  describe OmniauthManager do
    let(:dummy_provider) {:dummy}
    let(:args) do
      [
        'key',
        {name: :strategy_name}
      ]
    end
    let(:strategy_class) {DummyStrategy}

    class DummyStrategy
      attr_accessor :default_options
    end

    context '#initialize' do
      it 'create instance without strategies' do
        instance = described_class.new(dummy_provider, args)
        expect(instance.args).to eql args
        expect(instance.options).to eql args[1]
        expect(instance.provider).to eql dummy_provider
        expect(instance.strategy_name).to eql :strategy_name
      end
    end

    context '#strategy_class' do
      it 'return strategy when register' do
        strategy = strategy_class.new
        strategy.default_options = {name: :strategy_name}
        ::OmniAuth.strategies << strategy
        instance = described_class.new(dummy_provider, args)
        expect(instance.strategy_class).to eql strategy
      end

      it 'not return nothing when not strategy registered' do
        allow(::OmniAuth).to receive(:strategies).and_return []
        instance = described_class.new(dummy_provider, args)
        expect(instance.strategy_class).to be_nil
      end
    end
  end
end
