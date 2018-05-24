require "spec_helper"

describe OmniAuth::Strategies::Nordea do
  before do
    @token = "6e441b93-4c6d-4613-abed-b9976e7cff6c"
    @user_id = "ddc4beff-f08f-4856-99d2-ba5ac63c3eb9"

    # stub the API call made by the strategy to start the oauth dance
    stub_request(:post, "https://api.nordeaopenbanking.com/v1/authentication/access_token").
      to_return(
        headers: { "Content-Type" => "application/json" },
        body: MultiJson.encode(
          access_token: @token,
          expires_in:   3600,
          user_id:      @user_id))
  end

  it "redirects to start the OAuth flow" do
    get "/auth/nordea"
    assert_equal 302, last_response.status
    redirect = URI.parse(last_response.headers["Location"])
    redirect_params = CGI.parse(redirect.query)
    assert_equal "https", redirect.scheme
    assert_equal "api.nordeaopenbanking.com", redirect.host
    assert_equal [ENV["NORDEA_OAUTH_ID"]], redirect_params["client_id"]
    assert_equal ["code"], redirect_params["response_type"]
    assert_equal ["http://example.org/auth/nordea/callback"],
      redirect_params["redirect_uri"]
  end

  it "allows the scope to be determined dynamically" do
    @app = make_app(scope: lambda { |request| request.params['scope'] || 'identity' })
    # Pass the scope dynamically.
    get "/auth/nordea?scope=write-protected"
    assert_equal 302, last_response.status
    redirect = URI.parse(last_response.headers["Location"])
    redirect_params = CGI.parse(redirect.query)
    assert_equal ["write-protected"], redirect_params["scope"]
    # Use the default scope.
    get "/auth/nordea"
    assert_equal 302, last_response.status
    redirect = URI.parse(last_response.headers["Location"])
    redirect_params = CGI.parse(redirect.query)
    assert_equal ["identity"], redirect_params["scope"]
  end

  it "allows the scope to be determined statically" do
    @app = make_app(scope: "read-protected")
    get "/auth/nordea"
    assert_equal 302, last_response.status
    redirect = URI.parse(last_response.headers["Location"])
    redirect_params = CGI.parse(redirect.query)
    assert_equal ["read-protected"], redirect_params["scope"]
  end

  it "receives the callback" do
    # trigger the callback setting the state as a param and in the session
    state = SecureRandom.hex(8)
    get "/auth/nordea/callback", { "state" => state },
      { "rack.session" => { "omniauth.state" => state }}
    assert_equal 200, last_response.status

    omniauth_env = MultiJson.decode(last_response.body)
    assert_equal "nordea", omniauth_env["provider"]
    assert_equal @user_id, omniauth_env["uid"]
    assert_equal "NORDEA user", omniauth_env["info"]["name"]
  end

  it "fetches additional info when requested" do
    # change the app being tested:
    @app = make_app(fetch_info: true)

    # stub the API call to nordea
    account_info = {
      "email" => "john@example.org",
      "name"  =>  "John"
    }
    stub_request(:get, "https://api.nordeaopenbanking.com/v2/account").
      with(headers: { "Authorization" => "Bearer #{@token}" }).
      to_return(body: MultiJson.encode(account_info))

    # hit the OAuth callback
    state = SecureRandom.hex(8)
    get "/auth/nordea/callback", { "state" => state },
      { "rack.session" => { "omniauth.state" => state }}
    assert_equal 200, last_response.status

    # now make sure there's additional info in the omniauth env
    omniauth_env = MultiJson.decode(last_response.body)
    assert_equal "nordea", omniauth_env["provider"]
    assert_equal @user_id, omniauth_env["uid"]
    assert_equal "john@example.org", omniauth_env["info"]["email"]
    assert_equal "John", omniauth_env["info"]["name"]
    assert_equal account_info, omniauth_env["extra"]
  end

  describe "error handling" do
    it "renders an error when client_id is not informed" do
      @app = make_app(client_id: nil)
      get "/auth/nordea"
      assert_equal 302, last_response.status
      redirect = URI.parse(last_response.headers["Location"])
      assert_equal "/auth/failure", redirect.path
    end

    it "renders an error when client_secret is not informed" do
      @app = make_app(client_secret: "") # should also handle empty strings
      get "/auth/nordea"
      assert_equal 302, last_response.status
      redirect = URI.parse(last_response.headers["Location"])
      assert_equal "/auth/failure", redirect.path
    end
  end
end
