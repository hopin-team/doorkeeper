# frozen_string_literal: true

module Doorkeeper
  module Helpers
    # The RFC for resouce indicators allows for multiple to be specified using this syntax:
    #  GET /as/authorization.oauth2?response_type=code
    #  ...
    #  &scope=calendar%20contacts
    #  &resource=https%3A%2F%2Fcal.example.com%2F
    #  &resource=https%3A%2F%2Fcontacts.example.com%2F
    #
    # The default ActionController query paramater parsing will not accept that as an array
    # so we've got to do it ourselves. Post body request parsing also sees the same issue.
    module ResourceIndicators
      def self.resource_identifier_from_request(existing_params, request)
        resource_params = params_from_query(request)
        resource_params = resource_params.merge(params_from_post(request)) unless resource_params.key?("resource")
        resource_params = ActionController::Parameters.new(resource_params).slice(:resource).permit(resource: [])
        existing_params.merge(resource_params)
      end

      def self.params_from_post(request)
        params = {}
        if request.raw_post && !params.key?("resource")
          parsed_body = CGI.parse(request.raw_post)
          resources = parsed_body["resource"].presence || parsed_body["resource[]"].presence
          params["resource"] = resources if resources
        end
        params
      end

      def self.params_from_query(request)
        params = {}
        URI.parse(request.original_url).query.then do |query|
          if query
            resource = CGI.parse(query)["resource"]
            params["resource"] = resource if resource
          end
        end
        params
      end
    end
  end
end
