class Xero::Api
  module Attachment

    def upload_attachment(entity, id:, file_name:, content_type:, attachment:, include_online: false)
      url = "#{entity_handler(entity)}/#{id}/Attachments/#{file_name}"
      url += "?IncludeOnline=true" if include_online
      headers = { 'Content-Type' => content_type, 'Accept' => 'application/json' }
      raw_response = attachment_connection(headers: headers).post do |request|
        request.url url 
        request.body = Faraday::UploadIO.new(attachment, content_type, file_name)
      end
      response(raw_response, entity: entity)
    end

    def attachment_connection(headers:)
      build_connection(endpoint_url, headers: headers) do |conn|
        add_authorization_middleware(conn)
        add_exception_middleware(conn)
        conn.request :url_encoded
        add_connection_adapter(conn)
      end
    end

  end
end

