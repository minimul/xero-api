$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'rspec'
require 'webmock/rspec'
require 'vcr'
require 'awesome_print'
require 'faker'
require_relative '../lib/xero/api'
require_relative 'support/credentials'

VCR.configure do |config|
  config.cassette_library_dir = File.expand_path("../vcr", __FILE__)
  config.hook_into :webmock
  config.filter_sensitive_data('<ACCESS_TOKEN>') { URI.encode_www_form_component(creds.token) }
  config.filter_sensitive_data('<OAUTH2_ACCESS_TOKEN>') { URI.encode_www_form_component(oauth2_creds.access_token) }
  config.filter_sensitive_data('<CONSUMER_KEY>') { URI.encode_www_form_component(creds.consumer_key) }
end

# @param name [String] cassette name, e.g. "somenamespace/some description"
# @param options [Hash] optional options to use_cassette(name, options)
# @yield the cassette
# @yield an Integer (unix epoch time) for use in creating unique ids per cassette
def use_cassette(name, options={})
  # Set VCR_RECORD=once to re_record
  record_option = ENV.fetch("VCR_RECORD") { "none" }.to_sym
  options = {record: record_option }.merge!(options)
  VCR.use_cassette(name, options) do |cassette|
    yield cassette, Time.now.to_i
  end
end

RSpec.configure do |config|
  config.example_status_persistence_file_path = 'spec/temp/spec_status.txt'
end

def endpoint
  Xero::Api::V2_ENDPOINT_BASE_URL
end
