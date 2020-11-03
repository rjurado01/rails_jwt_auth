# RailsJwtAuth

![Gem Version](https://badge.fury.io/rb/rails_jwt_auth.svg)
![Build Status](https://travis-ci.org/rjurado01/rails_jwt_auth.svg?branch=master)

Rails-API authentication solution based on JWT and inspired by Devise.

> This is documentation for version `2.x`. If you are using `1.x` version use this
[link](https://github.com/rjurado01/rails_jwt_auth/tree/1.x)

> Version 2.x introduces incompatible API changes.

## Table of Contents

- [Installation](#installation)
- [Configuration](#configuration)
- [Modules](#modules)
- [ORMs support](#orms-support)
- [Controller helpers](#controller-helpers)
- [Default Controllers API](#default-controllers-api)
- [Customize]()
    + [Controllers](#custom-controllers)
    + [Payload](#custom-payload)
    + [Responses](#custom-responses)
    + [Strong parameters](#custom-strong-parameters)
- [Examples](#examples)
- [Testing](#testing-rspec)
- [License](#license)

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

Only for ActiveRecord, generate migrations:

```bash
rails g rails_jwt_auth:migrate
```

## Configuration

You can edit configuration options into `config/initializers/rails_jwt_auth.rb` file created by generator.

| Option                                    | Default value              | Description                                                            |
| ----------------------------------        | ----------------           | ---------------------------------------------------------------------- |
| model_name                                | `'User'`                   | Authentication model name                                              |
| auth_field_name                           | `'email'`                  | Field used to authenticate user with password                          |
| email_auth_field                          | `'email'`                  | Field used to send emails                                              |
| email_regex                               | `URI::MailTo::EMAIL_REGEXP`| Regex used to validate email input on requests like reset password     |
| downcase_auth_field                       | `false`                    | Apply downcase to auth field when save user and when init session      |
| jwt_expiration_time                       | `7.days`                   | Tokens expiration time                                                 |
| jwt_issuer                                | `'RailsJwtAuth'`           | The "iss" (issuer) claim identifies the principal that issued the JWT  |
| simultaneous_sessions                     | `2`                        | Number of simultaneous sessions for an user. Set 0 to disable sessions |
| mailer_name                               | `'RailsJwtAuth::Mailer'`   | Authentication model name                                              |
| mailer_sender                             | `...@example.com`          | E-mail address which will be shown in RailsJwtAuth::Mailer             |
| send_email_change_requested_notification  | `true`                     | Notify original email when change is requested (unconfirmed)           |
| send_password_changed_notification        | `true`                     | Notify email when password changes                                     |
| confirmation_expiration_time              | `1.day`                    | Confirmation token expiration time                                     |
| reset_password_expiration_time            | `1.day`                    | Confirmation token expiration time                                     |
| deliver_later                             | `false`                    | Uses `deliver_later` method to send emails                             |
| invitation_expiration_time                | `2.days`                   | Time an invitation is valid and can be accepted                        |
| lock_strategy                             | `:none`                    | Strategy to be used to lock an account: `:none` or `:failed_attempts`  |
| unlock_strategy                           | `:time`                    | Strategy to use when unlocking accounts: `:time`, `:email` or `:both`  |
| unlock_in                                 | `60.minutes`               | Interval to unlock an account if `unlock_strategy` is `:time`          |
| reset_attempts_in                         | `60.minutes`               | Interval after which to reset failed attempts counter of an account    |
| maximum_attempts                          | `3`                        | Number of failed login attempts before locking an account              |
| confirm_email_url                         | `nil`                      | Your web url where emai link redirects with confirmation token         |
| reset_password_url                        | `nil`                      | Your web url where emai link redirects with reset password token       |
| accept_invitation_url                     | `nil`                      | Your web url where emai link redirects with invitation token           |
| unlock_account_url                        | `nil`                      | Your web url where emai link redirects with unlock token               |
| avoid_email_errors                        | `true`                     | Avoid returns email errors to avoid giving clue to an attacker         |

## Modules

It's composed of 6 modules:

| Module        | Description                                                                                                     |
| ------------- | --------------------------------------------------------------------------------------------------------------- |
| Authenticable | Hashes and stores a password in the database to validate the authenticity of a user while signing in            |
| Confirmable   | Sends emails with confirmation instructions and verifies whether an account is already confirmed during sign in |
| Recoverable   | Resets the user password and sends reset instructions                                                           |
| Trackable     | Tracks sign in and request timestamps and IP address                                                            |
| Invitable     | Allows you to invite an user to your application sending an invitation mail                                     |
| Lockable      | Locks the user after a specified number of failed sign in attempts                                              |

## ORMs support

RailsJwtAuth support both Mongoid and ActiveRecord.

For next examples `auth_field_name` and `email_field_name` are configured to use the field `email`.

**ActiveRecord**

```ruby
# app/models/user.rb
class User < ApplicationRecord
  include RailsJwtAuth::Authenticatable
  include RailsJwtAuth::Confirmable
  include RailsJwtAuth::Recoverable
  include RailsJwtAuth::Trackable
  include RailsJwtAuth::Invitable
  include RailsJwtAuth::Lockable

  validates :email, presence: true,
                    uniqueness: true,
                    format: URI::MailTo::EMAIL_REGEXP
end
```

Ensure you have executed migrate task: `rails g rails_jwt_auth:migrate` and you have uncomented all modules fields into generated [migration file](https://github.com/rjurado01/rails_jwt_auth/blob/master/lib/generators/templates/migration.rb).

**Mongoid**

```ruby
class User
  include Mongoid::Document
  include RailsJwtAuth::Authenticatable
  include RailsJwtAuth::Confirmable
  include RailsJwtAuth::Recoverable
  include RailsJwtAuth::Trackable
  include RailsJwtAuth::Invitable
  include RailsJwtAuth::Lockable

  field :email, type: String

  validates :email, presence: true,
                    uniqueness: true,
                    format: URI::MailTo::EMAIL_REGEXP
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
    Raises `RailsJwtAuth::NotAuthorized` exception when it fails.

-   **authenticate**

    Authenticate your controllers:

    ```ruby
    class MyController < ApplicationController
      before_action :authenticate
    end
    ```

    This helper is like `authenticate!` but it not raises exception

-   **current_user**

    Return current signed-in user.

-   **jwt_payload**

    Return current jwt payload.

-   **signed_in?**

    Verify if a user is signed in.

## Default Controllers API

|       Prefix     | Verb   | URI Pattern                    | Controller#Action                     |
| ---------------- | ------ | ------------------------------ | -----------------------------------   |
|          session | DELETE | /session(.:format)             | rails_jwt_auth/sessions#destroy       |
|                  | POST   | /session(.:format)             | rails_jwt_auth/sessions#create        |
|     registration | POST   | /registration(.:format)        | rails_jwt_auth/registrations#create   |
|          profile | GET    | /profile(.:format)             | rails_jwt_auth/profiles#show          |
|     mail_profile | PUT    | /profile/email(.:format)       | rails_jwt_auth/profiles#email         |
| password_profile | PUT    | /profile/password(.:format)    | rails_jwt_auth/profiles#password      |
|                  | PUT    | /profile(.:format)             | rails_jwt_auth/profiles#update        |
|    confirmations | POST   | /confirmations(.:format)       | rails_jwt_auth/confirmations#create   |
|     confirmation | PUT    | /confirmations/:id(.:format)   | rails_jwt_auth/confirmations#update   |
|  reset_passwords | POST   | /reset_passwords(.:format)     | rails_jwt_auth/reset_passwords#create |
|   reset_password | GET    | /reset_passwords/:id(.:format) | rails_jwt_auth/reset_passwords#show   |
|                  | PUT    | /reset_passwords/:id(.:format) | rails_jwt_auth/reset_passwords#update |
|      invitations | POST   | /invitations(.:format)         | rails_jwt_auth/invitations#create     |
|       invitation | GET    | /invitations/:id(.:format)     | rails_jwt_auth/invitations#show       |
|                  | PUT    | /invitations/:id(.:format)     | rails_jwt_auth/invitations#update     |
|   unlock_account | PUT    | /unlock_accounts/:id(.:format) | rails_jwt_auth/unlock_accounts#update |

### Session

Session api is defined by `RailsJwtAuth::SessionsController`.

1.  Get session token:

```js
{
  url: host/session,
  method: POST,
  data: {
    session: {
      email: 'user@email.com',
      password: '12345678'
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

Registration api is defined by `RailsJwtAuth::RegistrationsController`.

1.  Register user:

```js
{
  url: host/registration,
  method: POST,
  data: {
    user: {
      email: 'user@email.com',
      password: 'xxxx'
    }
  }
}
```

### Profile

Profile api let you get/update your user info and is defined by `RailsJwtAuth::ProfilesController`.

1. Get user info:

```js
{
  url: host/profile,
  method: GET,
  headers: { 'Authorization': 'Bearer auth_token'}
}
```

2. Update user info:

```js
{
  url: host/profile,
  method: PUT,
  data: {
    profile: {
      name: 'new_name',
    }
  },
  headers: { 'Authorization': 'Bearer auth_token'}
}
```

3. Update user password:

```js
{
  url: host/profile/password,
  method: PUT,
  data: {
    profile: {
      current_password: 'xxxx',
      password: 'yyyy',
    }
  },
  headers: { 'Authorization': 'Bearer auth_token'}
}
```

4. Update user email (needs confirmation module):

```js
{
  url: host/profile/email,
  method: PUT,
  data: {
    profile: {
      email: 'new@email.com',
      password: 'xxxx', # email change is protected by password
    }
  },
  headers: { 'Authorization': 'Bearer auth_token'}
}
```

### Confirmation

Confirmation api is defined by `RailsJwtAuth::ConfirmationsController`.

It is necessary to set a value for `confirmations_url` option into `config/initializers/rails_jwt_auth.rb`.

1.  Confirm user:

```js
{
  url: host/confirmations/:token,
  method: PUT
  data: {}
}
```

2.  Create confirmation (resend confirmation email):

```js
{
  url: host/confirmations,
  method: POST,
  data: {
    confirmation: {
      email: 'user@example.com'
    }
  }
}
```

### Password

Reset password api is defined by `RailsJwtAuth::ResetPasswordsController`.

1.  Send reset password email (init reset password process):

```js
{
  url: host/reset_passwords,
  method: POST,
  data: {
    reset_password: {
      email: 'user@example.com'
    }
  }
}
```

2.  Check token validation:

Used to verify token and show an alert in your web before new password is setted.

```js
{
  url: host/reset_passwords/:token,
  method: GET
}
```

3.  Update password:

```js
{
  url: host/passwords/:token,
  method: PUT,
  data: {
    reset_password: {
      password: '1234',
      password_confirmation: '1234'
    }
  }
}
```

### Invitations

Invitations api is provided by `RailsJwtAuth::InvitationsController`.

1.  Create an invitation and send email:

```js
{
  url: host/invitations,
  method: POST,
  data: {
    invitation: {
      email: 'user@example.com',
      // More fields of your user
    }
  }
}
```

2.  Check token validation:

Used to verify token and show an alert in your web before invitation data is completed.

```js
{
  url: host/invitations/:token,
  method: GET
}
```

3.  Accept an invitation:

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

### Unlocks

Unlock api is provided by `RailsJwtAuth::UnlocksController`.

1.  Unlock user:

```js
{
  url: host/unlock_accounts/:unlock_token,
  method: PUT,
  data: {}
}
```

## Customize

RailsJwtAuth offers an easy way to customize certain parts.

### Custom controllers

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

### Custom payload

If you need edit default payload used to generate jwt you can overwrite the method `to_token_payload` into your User class:

```ruby
class User < ApplicationRecord
  include RailsJwtAuth::Authenticatable
  ...

  def to_token_payload(request)
    {
      auth_token: auth_tokens.last,
      # add here your custom info
    }
  end
end
```

### Custom responses

You can overwrite `RailsJwtAuth::RenderHelper` to customize controllers responses 
without need to overwrite each controller.

Example:

```ruby
# app/controllers/concerns/rails_jwt_auth/render_helper.rb

module RailsJwtAuth
  module RenderHelper
    private

    def render_session(jwt, user)
      # add custom field to session response
      render json: {session: {jwt: jwt, my_custom_field: user.custom_field}}, status: 201
    end

  ...
end
```

### Custom strong parameters

You can overwrite `RailsJwtAuth::ParamsHelper` to customize controllers strong parameters 
without need to overwrite each controller.

Example:

```ruby
# app/controllers/concerns/rails_jwt_auth/params_helper.rb

module RailsJwtAuth
  module ParamsHelper
    private

    def registration_create_params
      # change root to :data
      params.require(:data).permit(:email, :password, :password_confirmation)
    end

  ...
end
```

#### Custom mailer

To use a custom mailer, create a class that extends RailsJwtAuth::Mailer, like this:

```ruby
class CustomMailer < RailsJwtAuth::Mailer
  def confirmation_instructions(user)
    # set your custom code here

    super
  end
end
```

Then, in your `config/initializers/rails_jwt_auth.rb`, set `config.mailer` to `"CustomMailer"`.

> If you only need to customize templates, overwrite files in 'app/views/rails_jwt_auth/mailer'


## Testing (rspec)

Require the RailsJwtAuth::Spec::Helpers helper module in `rails_helper.rb`.

```ruby
require 'rails_jwt_auth/spec_helpers'
...
RSpec.configure do |config|
  ...
  config.include RailsJwtAuth::SpecHelpers, type: :controller
end
```

And then we can just call sign_in(user) to sign in as a user:

```ruby
describe ExampleController
  it 'blocks unauthenticated access' do
    expect { get :index }.to raise_error(RailsJwtAuth::NotAuthorized)
  end

  it 'allows authenticated access' do
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
