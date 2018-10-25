
class Xero::Api
  class Error < StandardError
    attr_reader :fault
    def initialize(errors = nil)
      if errors
        @fault = errors
        super(errors)
      end
    end
  end

  # Raised on HTTP status code 400
  class BadRequest < Error; end

  # Raised on HTTP status code 401
  class Unauthorized < Error; end

  # Raised on HTTP status code 404
  class NotFound < Error; end

  # Raised on HTTP status code 412
  class PreconditionFailed < Error; end

  # Raised on HTTP status code 500
  class InternalError < Error; end
  
  # Raised on HTTP status code 501
  class NotImplemented < Error; end

  # Raised on HTTP status code 503
  class ServiceUnavailable < Error; end
end
