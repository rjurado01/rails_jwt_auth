$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "rails_jwt_auth/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "rails_jwt_auth"
  s.version     = RailsJwtAuth::VERSION
  s.authors     = ["rjurado"]
  s.email       = ["rjurado@openmailbox.org"]
  s.homepage    = "https://github.com/rjurado01/rails-token-auth"
  s.summary     = "Rails jwt authentication."
  s.description = "Rails authentication solution based on Warden and JWT and inspired by Devise."
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  s.add_dependency "rails", "~> 5.0"
  s.add_dependency "warden", "~> 1.2"
  s.add_dependency "jwt", "~> 1.5"
  s.add_dependency "bcrypt", "~> 3.1"
end
