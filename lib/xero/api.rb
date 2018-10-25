require 'json'
require 'uri'
require 'logger'
require_relative 'api/version'
require_relative 'api/configuration'
require_relative 'api/connection'
require_relative 'api/error'
require_relative 'api/raise_http_exception'
require_relative 'api/util'
require_relative 'api/attachment'
require_relative 'api/methods'

module Xero
  class Api
    extend Configuration
    include Connection
    include Util
    include Attachment
    include Methods

    attr_accessor :endpoint

    V2_ENDPOINT_BASE_URL  = 'https://api.xero.com/api.xro/2.0/'
    LOG_TAG = "[xero-api gem]"

    def initialize(attributes = {})
      raise Xero::Api::Error, "missing or blank keyword: token" unless attributes.key?(:token) and !attributes[:token].nil?
      attributes = default_attributes.merge!(attributes)
      attributes.each do |attribute, value|
        public_send("#{attribute}=", value)
      end
      @endpoint_url = get_endpoint
    end

    def default_attributes
      {
        endpoint: :accounting
      }
    end

    def connection(url: endpoint_url)
      @connection ||= authorized_json_connection(url)
    end

    def endpoint_url
      @endpoint_url.dup
    end

    private

    def get_endpoint
      V2_ENDPOINT_BASE_URL
    end
  end
end
