# RailsJwtAuth
Rails authentication solution based on Warden and JWT.

## Installation
Add this line to your application's Gemfile:

```ruby
gem 'rails_jwt_auth'
```

And then execute:
```bash
$ bundle
```

Or install it yourself as:
```bash
$ gem install rails_jwt_auth
```

Finally execute:
```bash
rails g rails_jwt_auth:install
```

## Configuration
You can edit configuration options into `config/initializers/auth_token_auth.rb` file created by generator.

| Option                  | Default value | Description |
| ----                    | ----          | ----          |
| model_name              | 'User'        | Authentication model name |
| auth_field_name         | 'email'       | Field used to authenticate user with password |
| auth_field_email        | true          | Validate auth field email format |
| jwt_expiration_time     | 7.days        | Tokens expiration time |
| jwt_issuer              | 'RailsJwtAuth'         | The "iss" (issuer) claim identifies the principal that issued the JWT |
| simultaneous_sessions   | 2             | Number of simultaneous sessions for an user |



## Authenticatable model

It is the model used to authenticate requests.  
You can change default model (User) usin the configuration property
`model_name`.

### ActiveRecord
Include `RailsJwtAuth::Authenticatable` module into your User class:

```ruby
# app/models/user.rb
class User < ApplicationRecord
  include RailsJwtAuth::Authenticatable
end
```

and create a migration to add this fields to User model:

* **email**: string _(change 'email' by your authentication field)_
* **password_digest**: string _(required by has_secure_password)_
* **auth_tokens**: string _(used to generate jwt)_

```ruby
# example migration
create_table :users do |t|
  t.string :email
  t.string :password_digest
  t.string :auth_tokens
end
```


### Mongoid
Include `RailsJwtAuth::Authenticatable` module into your User class:

```ruby
# app/models/user.rb
class User
  include Mongoid::Document
  include RailsJwtAuth::Authenticatable
end
```

Fields are added automatically.


## Controller helpers

RailsJwtAuth will create some helpers to use inside your controllers.

To use this helpers we need to include `WardenHelper` into `ApplicationController`:

```ruby
# app/controllers/application_controller.rb
class ApplicationController < ActionController::API
  include RailsJwtAuth::WardenHelper
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
Session api is defined by RailsJwtAuth::SessionController.

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
Registration api is defined by RailsJwtAuth::RegistrationController.

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

You can overwrite RailsJwtAuth controller to edit actions, responses,
permited parameters...

For example, if we want to change registration strong parameters we
create new registration controller inherited from default controller:


```ruby
# app/controllers/registrations_controller.rb
class RegistrationsController < RailsJwtAuth::RegistrationsController
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

## Testing (rspec)

Require the RailsJwtAuth::Spec::Helpers helper module in `spec_helper.rb`.

```ruby
  require 'rails_jwt_auth/spec/helpers'
  ...
  RSpec.configure do |config|
    ...
    config.include RailsJwtAuth::Spec::Helpers, :type => :controller
    ...
  end
```

And then in controller examples we can just call sign_in(user) to sign in as a user, or sign_out for examples that have no user signed in. Here's two quick examples:

```ruby
  it "blocks unauthenticated access" do
    sign_out

    expect { get :index }.to raise_error(RailsJwtAuth::NotAuthorizedError)
  end

  it "allows authenticated access" do
    sign_in

    get :index

    expect(response).to be_success
  end
```


## License
The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
