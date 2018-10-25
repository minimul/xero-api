require 'faraday'

# @private
module FaradayMiddleware
  # @private
  class RaiseHttpException < Faraday::Middleware
    def call(env)
      @app.call(env).on_complete do |response|
        case response.status
        when 200
        when 204
        when 400
          raise Xero::Api::BadRequest.new(error_message(response))
        when 401
          raise Xero::Api::Unauthorized.new(error_message(response))
        when 404
          raise Xero::Api::NotFound.new(error_message(response))
        when 412
          raise Xero::Api::PreconditionFailed.new(error_message(response))
        when 500
          raise Xero::Api::InternalError.new(error_message(response))
        when 501
          raise Xero::Api::NotImplemented.new(error_message(response))
        when 503
          raise Xero::Api::ServiceUnavailable.new(error_message(response))
        end
      end
    end

    def initialize(app)
      super app
    end

    private

    def error_message(response)
      error = ::JSON.parse(response.body)
    rescue => e
      response.body
    end
  end
end
