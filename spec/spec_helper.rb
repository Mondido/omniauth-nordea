ENV["SESSION_SECRET"] = "abcdefghjij"
ENV["NORDEA_OAUTH_ID"] = "12345"
ENV["NORDEA_OAUTH_SECRET"] = "klmnopqrstu"

require "rubygems"
require "bundler"
Bundler.setup(:default, :test)
require "omniauth/strategies/nordea"

require "cgi"
require "rspec"
require "rack/test"
require "sinatra"
require "webmock/rspec"

Dir["./spec/support/*.rb"].each { |f| require f }

WebMock.disable_net_connect!

OmniAuth.config.logger = Logger.new(StringIO.new)

RSpec.configure do |config|
  config.include Rack::Test::Methods
  config.expect_with :minitest

  def app
    @app || make_app
  end

  def make_app(omniauth_nordea_options={})
    client_id     = ENV["NORDEA_OAUTH_ID"]
    client_secret = ENV["NORDEA_OAUTH_SECRET"]
    if omniauth_nordea_options.has_key?(:client_id)
      client_id = omniauth_nordea_options.delete(:client_id)
    end
    if omniauth_nordea_options.has_key?(:client_secret)
      client_secret = omniauth_nordea_options.delete(:client_secret)
    end

    Sinatra.new do
      configure do
        enable :sessions
        set :show_exceptions, false
        set :session_secret, ENV["SESSION_SECRET"]
      end

      use OmniAuth::Builder do
        provider :nordea, client_id, client_secret, omniauth_nordea_options
      end

      get "/auth/nordea/callback" do
        MultiJson.encode(env['omniauth.auth'])
      end
    end
  end
end
