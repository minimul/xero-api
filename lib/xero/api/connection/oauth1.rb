module Xero
  class Api
    OAUTH1_BASE            = 'https://api.xero.com/oauth'
    OAUTH1_UNAUTHORIZED    = OAUTH1_BASE + '/RequestToken'
    OAUTH1_REDIRECT        = OAUTH1_BASE + '/Authorize'
    OAUTH1_ACCESS_TOKEN    = OAUTH1_BASE + '/AccessToken'

    attr_accessor :token, :token_secret
    attr_accessor :consumer_key, :consumer_secret

    module Connection::OAuth1

      def self.included(*)
        Xero::Api::Connection.add_authorization_middleware :oauth1
        super
      end

      def default_attributes
        super.merge!(
          token: nil, token_secret: nil,
          consumer_key: defined?(CONSUMER_KEY) ? CONSUMER_KEY : nil,
          consumer_secret: defined?(CONSUMER_SECRET) ? CONSUMER_SECRET : nil,
        )
      end

      def add_oauth1_authorization_middleware(conn)
        gem 'simple_oauth'
        require 'simple_oauth'
        conn.request :oauth, oauth_data
      end

      def use_oauth1_middleware?
        token != nil
      end

      private

      # Use with simple_oauth OAuth1 middleware
      # @see #add_authorization_middleware
      def oauth_data
        {
          consumer_key: @consumer_key,
          consumer_secret: @consumer_secret,
          token: @token,
          token_secret: @token_secret
        }
      end

    end
  end
end
