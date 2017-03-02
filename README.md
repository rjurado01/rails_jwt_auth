# RailsJwtAuth

Rails-API authentication solution based on Warden and JWT and inspired by Devise.

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

| Option                         | Default value     | Description                                                           |
| ------------------------------ | ----------------- | --------------------------------------------------------------------- |
| model_name                     | 'User'            | Authentication model name                                             |
| auth_field_name                | 'email'           | Field used to authenticate user with password                         |
| auth_field_email               | true              | Validate auth field email format                                      |
| jwt_expiration_time            | 7.days            | Tokens expiration time                                                |
| jwt_issuer                     | 'RailsJwtAuth'    | The "iss" (issuer) claim identifies the principal that issued the JWT |
| simultaneous_sessions          | 2                 | Number of simultaneous sessions for an user                           |
| mailer_sender                  |                   | E-mail address which will be shown in RailsJwtAuth::Mailer            |
| confirmation_url               | confirmation_path | Url used to create email link with confirmation token                 |
| confirmation_expiration_time   | 1.day             | Confirmation token expiration time                                    |
| reset_password_url             | password_path     | Url used to create email link with reset password token               |
| reset_password_expiration_time | 1.day             | Confirmation token expiration time                                    |

## Authenticatable

Hashes and stores a password in the database to validate the authenticity of a user while signing in.

### ActiveRecord

Include `RailsJwtAuth::Authenticatable` module into your User class:

```ruby
# app/models/user.rb
class User < ApplicationRecord
  include RailsJwtAuth::Authenticatable
end
```

and create a migration to add authenticable fields to User model:

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

## Confirmable

Sends emails with confirmation instructions and verifies whether an account is already confirmed during sign in.

### ActiveRecord

Include `RailsJwtAuth::Confirmable` module into your User class:

```ruby
# app/models/user.rb
class User < ApplicationRecord
  include RailsJwtAuth::Authenticatable
  include RailsJwtAuth::Confirmable
end
```

and create a migration to add confirmation fields to User model:

```ruby
# example migration
change_table :users do |t|
  t.string :confirmation_token
  t.datetime :confirmation_sent_at
  t.datetime :confimed_at
end
```

### Mongoid

Include `RailsJwtAuth::Confirmable` module into your User class:

```ruby
# app/models/user.rb
class User
  include Mongoid::Document
  include RailsJwtAuth::Authenticatable
  include RailsJwtAuth::Confirmable
end
```

## Recoverable

Resets the user password and sends reset instructions

### ActiveRecord

Include `RailsJwtAuth::Recoverable` module into your User class:

```ruby
# app/models/user.rb
class User < ApplicationRecord
  include RailsJwtAuth::Authenticatable
  include RailsJwtAuth::Recoverable
end
```

and create a migration to add recoverable fields to User model:

```ruby
# example migration
change_table :users do |t|
  t.string :reset_password_token
  t.datetime :reset_password_sent_at
end
```

### Mongoid

Include `RailsJwtAuth::Recoverable` module into your User class:

```ruby
# app/models/user.rb
class User
  include Mongoid::Document
  include RailsJwtAuth::Authenticatable
  include RailsJwtAuth::Recoverable
end
```

## Controller helpers

RailsJwtAuth will create some helpers to use inside your controllers.

To use this helpers we need to include `WardenHelper` into `ApplicationController`:

```ruby
# app/controllers/application_controller.rb
class ApplicationController < ActionController::API
  include RailsJwtAuth::WardenHelper
end
```

-   **authenticate!**

    Authenticate your controllers:

    ```ruby
    class MyController < ApplicationController
      before_action :authenticate!
    end
    ```

    This helper expect that token has been into **AUTHORIZATION** header.

-   **current_user**

    Return current signed-in user.

-   **signed_in?**

    Verify if a user is signed in.

## Default Controllers API

### Session

Session api is defined by RailsJwtAuth::SessionsController.

1.  Get session token:

```js
{
  url: host/session,
  method: POST,
  data: {
    session: {
      email: "user@email.com",
      password: "12345678"
    }
  }
}
```

2.  Delete session

```js
{
  url: host/session,
  method: DELETE,
  headers: { 'Authorization': 'Bearer auth_token'}
}
```

### Registration

Registration api is defined by RailsJwtAuth::RegistrationsController.

1.  Register user:

```js
{
  url: host/registration,
  method: POST,
  data: {
    user: {
      email: "user@email.com",
      password: "12345678"
    }
  }
}
```

2.  Delete user:

```js
{
  url: host/registration,
  method: DELETE,
  headers: { 'Authorization': 'Bearer auth_token'}
}
```

### Confirmation

Confirmation api is defined by RailsJwtAuth::ConfirmationsController.

1.  Confirm user:

```js
{
  url: host/confirmation,
  method: PUT
  data: {
    confirmation_token: "token"
  }
}
```

2.  Create confirmation (resend confirmation email):

```js
{
  url: host/confirmation,
  method: POST,
  data: {
    confirmation: {
      email: "user@example.com"
    }
  }
}
```

### Password

Password api is defined by RailsJwtAuth::PasswordsController.

1.  Send reset password email:

```js
{
  url: host/password,
  method: POST,
  data: {
    password: {
      email: "user@example.com"
    }
  }
}
```

2.  Update password:

```js
{
  url: host/password,
  method: PUT,
  data: {
    reset_password_token: "token",
    password: {
      password: '1234',
      password_confirmation: '1234'
    }
  }
}
```

## Custom controllers

You can overwrite RailsJwtAuth controllers to edit actions, responses,
permitted parameters...

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

## Custom responses

You can overwrite `RailsJwtAuth::RenderHelper` to customize controllers responses.

## Custom strong parameters

You can overwrite `RailsJwtAuth::ParamsHelper` to customize controllers strong parameters.

## Testing (rspec)

Require the RailsJwtAuth::Spec::Helpers helper module in `rails_helper.rb`.

```ruby
  require 'rails_jwt_auth/spec/helpers'
  ...
  RSpec.configure do |config|
    ...
    config.include RailsJwtAuth::Spec::Helpers, :type => :controller
  end
```

And then we can just call sign_in(user) to sign in as a user, or sign_out for examples that have no user signed in. Here's two quick examples:

```ruby
  describe ExampleController
    it "blocks unauthenticated access" do
      sign_out
      expect { get :index }.to raise_error(RailsJwtAuth::Errors::NotAuthorized)
    end

    it "allows authenticated access" do
      sign_in
      get :index
      expect(response).to be_success
    end
  end
```

## Locales

Copy `config/locales/en.yml` into your project `config/locales` folder and edit it.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
