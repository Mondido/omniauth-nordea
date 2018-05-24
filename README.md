# OmniAuth NordeaOB

## WORK IN PROGRESS

[OmniAuth](https://github.com/intridea/omniauth) strategy for authenticating
Nordea Open Banking users.


This is intended for apps already using OmniAuth, for apps that authenticate
against more than one service (eg: Heroku and GitHub), or apps that have
specific needs on session management. 


## Configuration

OmniAuth works as a Rack middleware. Mount this Nordea adapter with:

```ruby
use OmniAuth::Builder do
  provider :nordea, ENV.fetch("NORDEA_OAUTH_ID"), ENV.fetch("NORDEA_OAUTH_SECRET")
end
```

Obtain a `NORDEA_OAUTH_ID` and `NORDEA_OAUTH_SECRET` by creating an app at
the [Nordea Open Banking Portal](https://developer.nordeaopenbanking.com/).

Your Nordea OAuth client should be set to receive callbacks on
`/auth/nordea/callback`.


## Usage

Initiate the OAuth flow sending users to `/auth/nordea`.

Once the authorization flow is complete and the user is bounced back to your
application, check `env["omniauth.auth"]["credentials"]`. It contains both a
refresh token and an access token (identified just as `"token"`) to the
account.


### Basic account information

If you want this middleware to fetch additional Nordea account information like
the user email address and name, use the `fetch_info` option, like:

```ruby
use OmniAuth::Builder do
  provider :nordea, ENV.fetch("NORDEA_OAUTH_ID"), ENV.fetch("NORDEA_OAUTH_SECRET"),
    fetch_info: true
end
```

This sets name and email in the [omniauth auth hash][auth-hash]. You can access
it from your app via `env["omniauth.auth"]["info"]`.

[auth-hash]: https://github.com/intridea/omniauth/wiki/Auth-Hash-Schema

### OAuth scopes

[Nordea supports different OAuth scopes][oauth-scopes]. By default this
strategy will request global access to the account, but you're encouraged to
request for less permissions when possible.

[oauth-scopes]: https://developer.nordeaopenbanking.com/

To do so, configure it like:

```ruby
use OmniAuth::Builder do
  provider :nordea, ENV.fetch("NORDEA_OAUTH_ID"), ENV.fetch("NORDEA_OAUTH_SECRET"),
    scope: "identity"
end
```

This will trim down the permissions associated to the access token given back
to you.

The Oauth scope can also be decided dynamically at runtime. For example, you
could use a `scope` GET parameter if it exists, and revert to a default `scope`
if it does not:

```ruby
use OmniAuth::Builder do
  provider :nordea, ENV.fetch("NORDEA_OAUTH_ID"), ENV.fetch("NORDEA_OAUTH_SECRET"),
    scope: ->(request) { request.params["scope"] || "identity" }
end
```



## Example - Rails

Under `config/initializers/omniauth.rb`:

```ruby
Rails.application.config.middleware.use OmniAuth::Builder do
  provider :nordea, ENV.fetch("NORDEA_OAUTH_ID"), ENV.fetch("NORDEA_OAUTH_SECRET")
end
```

Then add to `config/routes.rb`:

```ruby
Example::Application.routes.draw do
  get "login" => "sessions#new"
  get "/auth/:provider/callback" => "sessions#create"
end
```

Controller support:

```ruby
class SessionsController < ApplicationController
  def new
    redirect_to "/auth/nordea"
  end

  def create
    access_token = request.env['omniauth.auth']['credentials']['token']
    # DO NOT store this token in an unencrypted cookie session
    # Please read "A note on security" below!
    nordea_api = Nordea::API.new(api_key: access_token)
    @apps = nordea_api.get_apps.body
  end
end
```

And view:

```erb
<h1>Your apps:</h1>

<ul>
  <% @apps.each do |app| %>
    <li><%= app["name"] %></li>
  <% end %>
</ul>
```

## A note on security

**Make sure your cookie session is encrypted before storing sensitive
information on it, like access tokens**. [encrypted_cookie][encrypted-cookie]
is a popular gem to do that in Ruby.

[encrypted-cookie]: https://github.com/cvonkleist/encrypted_cookie

Both Rails and Sinatra take a cookie secret, but that is only used to protect
against tampering; any information stored on standard cookie sessions can
easily be read from the client side, which can be further exploited to leak
credentials off your app.


## Meta

Released under the MIT license.
