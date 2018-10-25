require 'dotenv'

Dotenv.load

def creds
  if ENV['XERO_API_OAUTH2_ACCESS_TOKEN']
    oauth2_creds
  else
    oauth1_creds
  end
end

def oauth1_creds
  OpenStruct.new(
    {
      consumer_key: ENV['XERO_API_CONSUMER_KEY'],
      consumer_secret: ENV['XERO_API_CONSUMER_SECRET'],
      token: ENV['XERO_API_ACCESS_TOKEN'],
      token_secret: ENV['XERO_API_ACCESS_TOKEN_SECRET'],
    }
  )
end

def oauth2_creds
  OpenStruct.new(
    {
      access_token: ENV['XERO_API_OAUTH2_ACCESS_TOKEN'],
    }
  )
end
