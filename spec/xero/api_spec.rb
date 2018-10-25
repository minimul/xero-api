require 'spec_helper'

describe Xero::Api do


  it 'has a version number' do
    expect(Xero::Api::VERSION).not_to be nil
  end

  it 'has the proper arguments' do
    expect { Xero::Api.new }.to raise_error Xero::Api::Error, /missing or blank keyword/
    expect { Xero::Api.new(token: nil) }.to raise_error Xero::Api::Error, /missing or blank keyword/
    expect { Xero::Api.new(creds.to_h) }.to_not raise_error
  end


end

