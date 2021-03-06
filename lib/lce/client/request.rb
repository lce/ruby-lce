module Lce
  class Client
    module Request
      def get(resource = nil, id = nil, action = nil, format = nil, params = nil)
        p = path(resource, id, action, format)
        request(:get, p, params, format)
      end

      def post(resource = nil, params = nil)
        p = path(resource)
        request(:post, p, params)
      end


      private

      def path(resource = nil, id = nil, action = nil, format = nil)
        path = []
        path << api_version << resource.to_s if resource
        path << id.to_s if id
        path << action.to_s if action
        path = '/'+path.join('/')
        path += ".#{format}" if format
        return path
      end

      def request(action, path, params, format = nil)
        response = connection.send(action, path, params)
        if success?(response)
          return process_data(response.headers['content-type'], response.body)
        else
          error!(response)
          return nil
        end
      end

      def process_data(type, body)
        case type
          when 'application/json'
            process_json(body)
          when 'application/pdf'
            process_pdf(body)
        end
      end

      def process_pdf(body)
        body
      end
      
      def process_json(body)
        if body.data.is_a? Array
          a = PaginatedArray.new(body[:count], body[:page], body[:per_page])
          body.data.each do |d|
            a << d
          end
          return a
        else
          return body.data
        end
      end
      
      def success?(response)
        response.status.between?(200, 299) && (response.headers['content-type'] != 'application/json' || response.body.status == "success")
      end
      
      def error!(response)
        if response.body.error
          case response.body.error.type
            when 'access_denied'
              raise Lce::Client::AccessDenied.new(response.body.error.message, response.body.error.type, response.body.error.details)
            when 'account_disabled'
              raise Lce::Client::AccountDisabled.new(response.body.error.message, response.body.error.type, response.body.error.details)
            else
              raise Lce::Client::LceError.new(response.body.error.message, response.body.error.type, response.body.error.details)              
          end
        end
      end
    end
  end
end
