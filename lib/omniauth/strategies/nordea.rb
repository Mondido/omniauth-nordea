require 'omniauth-oauth2'

module OmniAuth
  module Strategies
    class Nordea < OmniAuth::Strategies::OAuth2
      AuthUrl = ENV["NORDEA_AUTH_URL"] || "https://api.nordeaopenbanking.com/v1"
      ApiUrl  = ENV["NORDEA_API_URL"]  || "https://api.nordeaopenbanking.com/v1"

      option :client_options, {
        site:          AuthUrl,
        authorize_url: "#{AuthUrl}/oauth/authorize",
        token_url:     "#{AuthUrl}/authentication"
      }

      # whether we should make another API call to NORDEA to fetch
      # additional account info like the real user name and email
      option :fetch_info

      uid do
        access_token.params["user_id"]
      end

      info do
        if options.fetch_info
          email_hash        = Digest::MD5.hexdigest(account_info['email'].to_s)
          default_image_url = "https://dashboard.nordea.com/ninja-avatar-48x48.png"
          image_url         = "https://secure.gravatar.com/avatar/#{email_hash}.png?d=#{default_image_url}"

          {
            name:  account_info["name"],
            email: account_info["email"],
            image: image_url,
          }
        else
          { name: "NORDEA user" } # only mandatory field
        end
      end

      extra do
        if options.fetch_info
          account_info
        else
          {}
        end
      end

      # override method in OmniAuth::Strategies::OAuth2 to error
      # when we don't have a client_id or secret:
      def request_phase
        if missing_client_id?
          fail!(:missing_client_id)
        elsif missing_client_secret?
          fail!(:missing_client_secret)
        else
          super
        end
      end

      def authorize_params
        super.tap do |params|
          # Allow the scope to be determined dynamically based on the request.
          if params.scope.respond_to?(:call)
            params.scope = params.scope.call(request)
          end
        end
      end

      def account_info
        @account_info ||= MultiJson.decode(nordea_api.get("/v1/account").body)
      end

      def nordea_api
        @NORDEA_api ||= Faraday.new(
          url: ApiUrl,
          headers: {
            "Accept" => "application/vnd.nordea+json; version=3",
            "Authorization" => "Bearer #{access_token.token}",
          })
      end

      def missing_client_id?
        [nil, ""].include?(options.client_id)
      end

      def missing_client_secret?
        [nil, ""].include?(options.client_secret)
      end
    end
  end
end
