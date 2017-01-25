$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "rails_token_auth/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "rails_token_auth"
  s.version     = RailsTokenAuth::VERSION
  s.authors     = ["rjurado"]
  s.email       = ["rjurado@openmailbox.org"]
  s.homepage    = "https://github.com/rjurado01/rails-token-auth"
  s.summary     = "Rails token authentication."
  s.description = "Rails authentication utilities usign jwt token."
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  s.add_dependency "rails", "~> 5.0.1"
  s.add_dependency "warden", "~> 1.2.6"
  s.add_dependency "jwt", "~> 1.5.6"
  s.add_dependency "bcrypt", "~> 3.1.11"
end
