class Xero::Api
  module Methods

    def get(entity, all: false, id: nil, params: nil, headers: nil, path: nil, modified_since: nil, parse_entity: true)
      route = build_resource(entity, id: id, params: params, path: path)
      final_headers = handle_headers(headers, modified_since)
      if all
        enumerator = get_all(entity, path: route, headers: final_headers, parse_entity: parse_entity)
      else
        request(:get, path: route, entity: entity, headers: final_headers, parse_entity: parse_entity)
      end
    end

    def create(entity, payload:, params: nil, path: nil)
      route = build_resource(entity, params: params, path: path)
      request(:put, path: route, entity: entity, payload: payload)
    end

    def update(entity, id:, payload:, params: nil, path: nil)
      route = build_resource(entity, id: id, params: params, path: path)
      payload.merge!({ "Id": id })
      request(:post, path: route, entity: entity, payload: payload)
    end

    def delete(entity, id:, params: nil, path: nil)
      route = build_resource(entity, id: id, path: path)
      request(:delete, path: route, entity: entity)
    end

    private

    def build_resource(entity, id: nil, params: nil, path: nil)
      route = entity_handler(entity)
      route = "#{route}/#{id}" if id
      route = "#{route}/#{path}" if path
      route = add_params(route: route, params: params) if params
      route
    end

    def handle_headers(headers, modified_since)
      h = {}
      h.merge!(headers) if headers
      h.merge!(if_modified_hash(modified_since)) if modified_since
      h
    end

    def if_modified_hash(modified_since)
      { 'If-Modified-Since' => standard_date(modified_since) }
    end

    def get_all(entity, path:, headers:, parse_entity:)
      max = 100
      Enumerator.new do |enum_yielder|
        number = 0
        begin
          number += 1
          paged_path = add_params(route: path, params: { page: number })
          results = request(:get, path: paged_path, entity: entity, headers: headers, parse_entity: parse_entity)
          results.each do |result|
            enum_yielder.yield(result)
          end if results
        end while (results ? results.size == max : false)
      end
    end

  end
end
