# RailsTokenAuth
Rails token authentication solution for Rails based on Warden and JWT.

## Usage
How to use my plugin.

## Installation
Add this line to your application's Gemfile:

```ruby
gem 'rails_token_auth'
```

And then execute:
```bash
$ bundle
```

Or install it yourself as:
```bash
$ gem install rails_token_auth
```

## Configuration
Include `AuthModel` module into your User class:

```ruby
# app/models/user.rb
class User
  include Mongoid::Document
  include Mongoid::AuthModel
end
```

Include `WardenHelper` into your `ApplicationController`:

```ruby
# app/controllers/application_controller.rb
class ApplicationController < ActionController::API
  include WardenHelper
end
```

Authenticate your controllers:

```ruby
class MyController < ApplicationController
  before_action :authenticate!
end
```

## Contributing
Contribution directions go here.

## License
The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
