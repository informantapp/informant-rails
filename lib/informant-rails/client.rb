require 'net/http'

module InformantRails
  class Client
    @requests = {}

    def self.record(env)
      new_request.request_url = env['HTTP_REFERER']
    end

    def self.inform_action(controller_name, action)
      if request
        request.filename = controller_name
        request.action = action
      end
    end

    def self.inform(model)
      request.process_model(model) if request && model
    end

    def self.process
      if Config.api_token.present? && request && request.models.any?
        Net::HTTP.post_form(api_url, request.as_json)
      end
      remove_request
    end

    def self.request
      @requests[request_id]
    end

    private

    def self.new_request
      @requests[request_id] = Request.new
    end

    def self.remove_request
      @requests.delete(request_id)
    end

    def self.request_id
      Thread.current.object_id
    end

    def self.api_url
      @api_url ||= URI([
        'http://informant-production.herokuapp.com/api/v1',
        InformantRails::Config.api_token,
        InformantRails::Config.server_environment
      ].join('/'))
    end
  end
end