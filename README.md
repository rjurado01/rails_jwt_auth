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

## Configuration
You can edit configuration options into `config/initializers/auth_token_auth.rb` file created by generator.


## Authenticatable model

### ActiveRecord
Include `RailsTokenAuth::Authenticatable` module into your User class:

```ruby
# app/models/user.rb
class User < ApplicationRecord
  include RailsTokenAuth::Authenticatable
end
```

and add this fields to User model by migration:

* email: string _(email is the default authentication field, you can
  configure other field)_
* password_digest: string _(required by has_secure_password)_
* auth_token: string _(used to generate jwt)_

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

To use this helpers we need to include `WardenHelper` into `ApplicationController`:

```ruby
# app/controllers/application_controller.rb
class ApplicationController < ActionController::API
  include WardenHelper
end
```

* **authenticate!**

  Authenticate your controllers:

  ```ruby
  class MyController < ApplicationController
    before_action :authenticate!
  end
  ```
  This helper expect that token has been into **AUTHORIZATION** header.

* **current_user**

  Return current signed-in user.

* **signed_in?**

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
  headers: { 'Authorization': 'auth_token'}
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
  headers: { 'Authorization': 'auth_token'}
}
```

To remove registration remove resource registration from
`config/routes.rb` file.

To create your your own registration controller see this.


## Custom controllers

You can overwrite RailsTokenAuth controller to edit actions, responses,
permited parameters...

For example, if we want to change registration strong parameters we
create new registration controller inherited from default controller:


```ruby
# app/controllers/registrations_controller.rb
class RegistrationsController < RailsTokenAuth::RegistrationsController
  private

  def create_params
    params.require(:user).permit(:email, :name, :surname, :password, :password_confirmation)
  end
end
```

And edit route resource to use it:

```ruby
# config/routes.rb
resource :registration, controller: 'registrations', only: [:create, :update, :destroy]

```


## License
The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
