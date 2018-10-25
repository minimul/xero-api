class Xero::Api
  module Util

    def add_params(route:, params:)
      uri = URI.parse(route)
      params.each do |p|
        new_query_ar = URI.decode_www_form(uri.query || '') << p.to_a
        uri.query = URI.encode_www_form(new_query_ar)
      end
      uri.to_s
    end

    def standard_date(date)
      date.strftime('%Y-%m-%dT%H:%M:%S')
    rescue => e
      raise Xero::Api::Error, date_method_error_msg(e)
    end

    def json_date(date)
      date.strftime("/Date(%s%L)/")
    rescue => e 
      raise Xero::Api::Error, date_method_error_msg(e)
    end

    def parse_json_date(datestring)
      seconds_since_epoch = datestring.scan(/[0-9]+/)[0].to_i / 1000.0
      Time.at(seconds_since_epoch)
    end

    def entity_handler(entity)
      if entity.is_a?(Symbol)
        snake_to_camel(entity)
      else
        entity
      end
    end

    def snake_to_camel(sym)
      sym.to_s.split('_').collect(&:capitalize).join
    end

    private 
    
    def date_method_error_msg(e)
      if e.message =~ /undefined method \`strftime/
        "The argument needs to be an instance of Date|Time|DateTime"
      else
        e.message
      end
    end

  end
end

