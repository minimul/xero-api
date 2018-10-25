BASE_GEMS = proc do
  gem 'xero-api', path: '.'
  # This app
  gem 'sinatra'
  gem 'sinatra-contrib'

  # Creds from ../.env
  gem 'dotenv'
end

BASE_SETUP = proc do
  # Webhook support
  require 'json'
  require 'openssl'
  require 'base64'

  Dotenv.load "#{__dir__}/../.env"
end

BASE_APP_CONFIG = proc do
  PORT  = ENV.fetch("PORT", 9393)

  configure do
    $VERBOSE = nil # silence redefined constant warning
    register Sinatra::Reloader
  end

  set :port, PORT

  helpers do
    def base_url
      "http://localhost:#{PORT}"
    end
  end

end
