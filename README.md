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

## Authenticatable

### Mongoid
Include `RailsTokenAuth::Authenticatable` module into your User class:

```ruby
# app/models/user.rb
class User
  include Mongoid::Document
  include RailsTokenAuth::Authenticatable
end
```

### ActiveRecord
Include `RailsTokenAuth::Authenticatable` module into your User class:

```ruby
# app/models/user.rb
class User < ApplicationRecord
  include RailsTokenAuth::Authenticatable
end
```

and add this fields to User model:

* email: string
* password_digest: string
* auth_token: string

### Controllers
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

### Usage

1. Get session token:

```
{
  url: host/session,
  method: POST,
  data: {
    email: "user@email.com",
    password: "12345678"
  }
}
```

2. Delete session

```
{
  url: host/session,
  method: DELETE,
}
```

## License
The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
