# RailsTokenAuth
Rails token authentication solution for Rails based on Warden and JWT.

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

Finally execute:
```bash
rails g rails_token_auth:install
```

## Authenticatable model

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

### Mongoid
Include `RailsTokenAuth::Authenticatable` module into your User class:

```ruby
# app/models/user.rb
class User
  include Mongoid::Document
  include RailsTokenAuth::Authenticatable
end
```

Fields are added automatically.

## Controller helpers

RailsTokenAuth will create some helpers to use inside your controllers.

Include `WardenHelper` into your `ApplicationController`:

```ruby
# app/controllers/application_controller.rb
class ApplicationController < ActionController::API
  include WardenHelper
end
```

* authenticate!

  Authenticate your controllers:

  ```ruby
  class MyController < ApplicationController
    before_action :authenticate!
  end
  ```

* current_user

  Return current signed-in user.

* signed_in?

  Verify if a user is signed in.

## Session
Session api is defined by RailsTokenAuth::SessionController.

1. Get session token:

```js
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

```js
{
  url: host/session,
  method: DELETE,
}
```

## Registration
Registration api is defined by RailsTokenAuth::RegistrationController.

1. Register user:

```js
{
  url: host/registration,
  method: POST,
  data: {
    email: "user@email.com",
    password: "12345678"
  }
}
```

2. Delete user:

```js
{
  url: host/registration,
  method: DELETE,
}
```


## License
The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
