require 'faraday'
require 'faraday_middleware'
require 'faraday/detailed_logger'

class Xero::Api
  module Connection
    AUTHORIZATION_MIDDLEWARES = []

    def Connection.add_authorization_middleware(strategy_name)
      Connection::AUTHORIZATION_MIDDLEWARES << strategy_name
    end

    def authorized_json_connection(url, headers: nil)
      headers ||= {}
      headers['Accept'] ||= 'application/json' # required "we'll only accept JSON". Can be changed to any `+json` media type.
      headers['Content-Type'] ||= 'application/json;charset=UTF-8' # required when request has a body, else harmless
      build_connection(url, headers: headers) do |conn|
        add_authorization_middleware(conn)
        add_exception_middleware(conn)
        conn.request :url_encoded
        add_connection_adapter(conn)
      end
    end

    def authorized_multipart_connection(url)
      headers = { 'Content-Type' => 'multipart/form-data' }
      build_connection(url, headers: headers) do |conn|
        add_authorization_middleware(conn)
        add_exception_middleware(conn)
        conn.request :multipart
        add_connection_adapter(conn)
      end
    end

    def build_connection(url, headers: nil)
      Faraday.new(url: url) { |conn|
        conn.response :detailed_logger, Xero::Api.logger, LOG_TAG if Xero::Api.log
        conn.headers.update(headers) if headers
        yield conn if block_given?
      }
    end

    def request(method, path:, entity: nil, payload: nil, headers: nil, parse_entity: false)
      raw_response = raw_request(method, conn: connection, path: path, payload: payload, headers: headers)
      response(raw_response, entity: entity, parse_entity: parse_entity)
    end

    def raw_request(method, conn:, path:, payload: nil, headers: nil)
      conn.public_send(method) do |req|
        req.headers.update(headers) if headers
        case method
        when :get, :delete
          req.url path
        when :post, :put
          req.url path
          req.body = payload.to_json
        else raise Xero::Api::Error, "Unhandled request method '#{method.inspect}'"
        end
      end
    end

    def response(resp, entity: nil, parse_entity: false)
      data = parse_response_body(resp)
      parse_entity && entity ? entity_response(data, entity) : data
    rescue => e
      msg = "#{LOG_TAG} response parsing error: entity=#{entity.inspect} body=#{resp.body.inspect} exception=#{e.inspect}"
      Xero::Api.logger.debug { msg }
      data
    end

    def parse_response_body(resp)
      body = resp.body
      case resp.headers['Content-Type']
      when /json/ then JSON.parse(body)
      else body
      end
    end

    private

    def entity_response(data, entity)
      entity_name = entity_handler(entity)
      entity_body = data
      entity_body.fetch(entity_name) do
        msg = "#{LOG_TAG} entity name not in that top-level of the response body: entity_name=#{entity_name}"
        Xero::Api.logger.debug { msg }
        data
      end
    end

    def add_connection_adapter(conn)
      conn.adapter Faraday.default_adapter
    end

    def add_exception_middleware(conn)
      conn.use FaradayMiddleware::RaiseHttpException
    end

    def add_authorization_middleware(conn)
      Connection::AUTHORIZATION_MIDDLEWARES.find(proc do
        raise Xero::Api::Error, 'Add a configured authorization_middleware'
      end) do |strategy_name|
        next unless public_send("use_#{strategy_name}_middleware?")
        public_send("add_#{strategy_name}_authorization_middleware", conn)
        true
      end
    end

    require_relative 'connection/oauth1'
    include OAuth1
    require_relative 'connection/oauth2'
    include OAuth2
  end
end
