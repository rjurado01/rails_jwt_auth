module RailsJwtAuth
  class StrategyNotFound < NameError
    def initialize(strategy)
      @strategy = strategy
      super("Could not find a strategy with name `#{strategy}'. " \
        "Please ensure it is required or explicitly set it using the :strategy_class option.")
    end
  end

  class OmniauthManager
    # Based on https://github.com/heartcombo/devise Config

    attr_accessor :strategy
    attr_reader :args, :options, :provider, :strategy_name

    def initialize(provider, args)
      @provider = provider
      @args = args
      @options = @args.last.is_a?(Hash) ? @args.last : {}
      @strategy = nil
      @strategy_class = nil
      @strategy_name  = options[:name] || @provider
    end

    def strategy_class
      @strategy_class ||= ::OmniAuth.strategies.find do |strategy|
        strategy.to_s =~ /#{::OmniAuth::Utils.camelize(strategy_name)}$/ ||
          strategy.default_options[:name] == strategy_name
      end
    end
  end
end
