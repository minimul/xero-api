require 'bundler/inline'

require File.expand_path(File.join('..', 'base'), __FILE__)

install_gems = true
gemfile(install_gems) do
  source 'https://rubygems.org'

  instance_eval(&BASE_GEMS)

  gem 'simple_oauth'
  gem 'omniauth'
  gem 'omniauth-xero'
end

instance_eval(&BASE_SETUP)

class OAuthApp < Sinatra::Base
  instance_eval(&BASE_APP_CONFIG)

  CONSUMER_KEY = ENV['XERO_API_CONSUMER_KEY']
  CONSUMER_SECRET = ENV['XERO_API_CONSUMER_SECRET']

  use Rack::Session::Cookie, secret: '34233adasfqewrq453agqr9lasfa'
  use OmniAuth::Builder do
    provider :xero, CONSUMER_KEY, CONSUMER_SECRET
  end

  get '/' do
    @auth_data = oauth_data
    @port = PORT
    erb :index
  end

  get '/customers' do
    if session[:token]
      api = Xero::Api.new(oauth_data)
      @resp = api.get :contacts, all: true, params: { where: 'isCustomer=true' }
    end
    erb :customers
  end

  get '/auth/xero/callback' do
    auth = env["omniauth.auth"][:credentials]
    session[:token] = auth[:token]
    session[:secret] = auth[:secret]
    file_name = "#{__dir__}/../.env"
    if env = File.read(file_name)
      res = env.sub(/(XERO_API_ACCESS_TOKEN=)(.*)/, '\1' + session[:token])
      res = res.sub(/(XERO_API_ACCESS_TOKEN_SECRET=)(.*)/, '\1' + session[:secret])
      File.open(file_name, "w") {|file| file.puts res }
    end
    @url = base_url
    erb :callback
  end

  def oauth_data
    {
      consumer_key: CONSUMER_KEY,
      consumer_secret: CONSUMER_SECRET,
      token: session[:token],
      token_secret: session[:secret]
    }
  end
end

OAuthApp.run!
