# RailsJwtAuth
[![Gem Version](https://badge.fury.io/rb/rails_jwt_auth.svg)](https://badge.fury.io/rb/rails_jwt_auth)
![Build Status](https://travis-ci.org/rjurado01/rails_jwt_auth.svg?branch=master)

Rails-API authentication solution based on JWT and inspired by Devise.

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

| Option                         | Default value     | Description                                                            |
| ------------------------------ | ----------------- | ---------------------------------------------------------------------- |
| model_name                     | 'User'            | Authentication model name                                              |
| auth_field_name                | 'email'           | Field used to authenticate user with password                          |
| auth_field_email               | true              | Validate auth field email format                                       |
| email_regex                    | see config file   | Regex used to Validate email format                                    |
| jwt_expiration_time            | 7.days            | Tokens expiration time                                                 |
| jwt_issuer                     | 'RailsJwtAuth'    | The "iss" (issuer) claim identifies the principal that issued the JWT  |
| simultaneous_sessions          | 2                 | Number of simultaneous sessions for an user. Set 0 to disable sessions |
| mailer_sender                  |                   | E-mail address which will be shown in RailsJwtAuth::Mailer             |
| confirmation_url               | confirmation_path | Url used to create email link with confirmation token                  |
| confirmation_expiration_time   | 1.day             | Confirmation token expiration time                                     |
| reset_password_url             | password_path     | Url used to create email link with reset password token                |
| reset_password_expiration_time | 1.day             | Confirmation token expiration time                                     |
| set_password_url               | password_path     | Url used to create email link with set password token                  |
| deliver_later                  | false             | Uses `deliver_later` method to send emails                             |
| invitation_expiration_time     | 2.days            | Time an invitation is valid and can be accepted                        |
| accept_invitation_url          | invitations_path  | URL used to create email link with invitation token                    |

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

  field :email, type: String
end
```

Gem fields are added automatically.

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
  t.string :email # if it doesn't exist yet
  t.string :unconfirmed_email
  t.string :confirmation_token
  t.datetime :confirmation_sent_at
  t.datetime :confirmed_at
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

This module needs that model has `email` field.

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

## Trackable

Tracks sign in timestamps and IP address.

### ActiveRecord

Include `RailsJwtAuth::Trackable` module into your User class:

```ruby
# app/models/user.rb
class User < ApplicationRecord
  include RailsJwtAuth::Authenticatable
  include RailsJwtAuth::Trackable
end
```

and create a migration to add recoverable fields to User model:

```ruby
# example migration
change_table :users do |t|
  t.string :last_sign_in_ip
  t.datetime :last_sign_in_at
end
```

### Mongoid

Include `RailsJwtAuth::Trackable` module into your User class:

```ruby
# app/models/user.rb
class User
  include Mongoid::Document
  include RailsJwtAuth::Authenticatable
  include RailsJwtAuth::Trackable
end
```

## Invitable

This module allows you to invite an user to your application sending an invitation mail with a unique link and complete registration by setting user's password.

### ActiveRecord

Include `RailsJwtAuth::Invitable` module in your User model:

```ruby
# app/models/user.rb
class User < ApplicationRecord
  include RailsJwtAuth::Authenticatable
  include RailsJwtAuth::Invitable
end
```

And create the corresponding migration

```ruby
# Example migration
change_table :users do |t|
  t.string :invitation_token
  t.datetime :invitation_sent_at
  t.datetime :invitation_accepted_at
  t.datetime :invitation_created_at
end
```

### Mongoid

Include `RailsJwtAuth::Invitable` module in your User model:

```ruby
# app/models/user.rb
class User < ApplicationRecord
  include RailsJwtAuth::Authenticatable
  include RailsJwtAuth::Invitable
end
```

## Controller helpers

RailsJwtAuth will create some helpers to use inside your controllers.

To use this helpers we need to include `AuthenticableHelper` into `ApplicationController`:

```ruby
# app/controllers/application_controller.rb
class ApplicationController < ActionController::API
  include RailsJwtAuth::AuthenticableHelper
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

### Invitations

Invitations api is provided by RailsJwtAuth::InvitationsController.

1.  Create an invitation and send email:

```js
{
  url: host/invitations,
  method: POST,
  data: {
    invitation: {
      email: "user@example.com",
      // More fields of your user
    }
  }
}
```

2.  Accept an invitation:

```js
{
  url: host/invitations/:invitation_token,
  method: PUT,
  data: {
    invitation: {
      password: '1234',
      password_confirmation: '1234'
    }
  }
}
```

Note: To add more fields, see "Custom strong parameters" below.

## Custom controllers

You can overwrite RailsJwtAuth controllers to edit actions, responses,
permitted parameters...

For example, if we want to call custom method when user is created we need to
create new registration controller inherited from default controller:

```ruby
# app/controllers/registrations_controller.rb
class RegistrationsController < RailsJwtAuth::RegistrationsController
  ...

  def create
    user = RailsJwtAuth.model.new(create_params)
    user.do_something_custom
    ...
  end

  ...
end
```

And edit route resource to use it:

```ruby
# config/routes.rb
resource :registration, controller: 'registrations', only: [:create, :update, :destroy]
```

## Custom payload

If you need edit default payload used to generate jwt you can overwrite the method `to_token_payload` into your User class:

```ruby
class User < ApplicationRecord
  include RailsJwtAuth::Authenticatable
  ...

  def to_token_payload(request)
    {
      auth_token: regenerate_auth_token,
      # add here your custom info
    }
  end
end
```

## Custom responses

You can overwrite `RailsJwtAuth::RenderHelper` to customize controllers responses.

## Custom strong parameters

You can overwrite `RailsJwtAuth::ParamsHelper` to customize controllers strong parameters.

## Edit user information

This is a controller example that allows users to edit their `email` and `password`.

```ruby
class CurrentUserController < ApplicationController
  before_action 'authenticate!'

  def update
    if update_params[:password]
      current_user.update_with_password(update_params)
    else
      current_user.update_attributes(update_params)
    end
  end

  private

  def update_params
    params.require(:user).permit(:email, :current_password, :password)
  end
end
```

## Register users with random password

This is a controller example that allows admins to register users with random password and send email to reset it.
If registration is sucess it will send email to `set_password_url` with reset password token.

```ruby
class UsersController < ApplicationController
  before_action 'authenticate!'

  def create
    user = User.new(create_params)
    user.set_and_send_password_instructions ? render_204 : render_422(user.errors.details)
  end

  private

  def create_params
    params.require(:user).permit(:email)
  end
end
```

## Testing (rspec)

Require the RailsJwtAuth::Spec::Helpers helper module in `rails_helper.rb`.

```ruby
  require 'rails_jwt_auth/spec_helpers'
  ...
  RSpec.configure do |config|
    ...
    config.include RailsJwtAuth::Spec::Helpers, :type => :controller
  end
```

And then we can just call sign_in(user) to sign in as a user:

```ruby
  describe ExampleController
    it "blocks unauthenticated access" do
      expect { get :index }.to raise_error(RailsJwtAuth::Errors::NotAuthorized)
    end

    it "allows authenticated access" do
      sign_in user
      get :index
      expect(response).to be_success
    end
  end
```

## Locales

Copy `config/locales/en.yml` into your project `config/locales` folder and edit it.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
