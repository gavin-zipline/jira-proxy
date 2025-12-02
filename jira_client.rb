# frozen_string_literal: true

require "faraday"
require "json"
require "base64"

class JiraClient
  class Error < StandardError
    attr_reader :status

    def initialize(message, status: nil, cause: nil)
      super(message)
      @status = status
      @cause = cause
    end
  end

  def initialize(base_url:, email:, api_token:)
    @base_url = base_url
    @email = email
    @api_token = api_token
    @connection = build_connection
  end

  def get_issue(key)
    response = @connection.get("rest/api/3/issue/#{key}")
    JSON.parse(response.body)
  rescue Faraday::Error => e
    status = e.response[:status] if e.respond_to?(:response) && e.response
    raise Error.new("Jira request failed", status: status, cause: e)
  rescue JSON::ParserError => e
    raise Error.new("Failed to parse Jira response", cause: e)
  end

  private

  def build_connection
    Faraday.new(url: @base_url) do |f|
      f.request :json
      f.response :raise_error
      f.headers["Accept"] = "application/json"
      f.headers["Authorization"] = "Basic #{encoded_credentials}"
      f.adapter Faraday.default_adapter
    end
  end

  def encoded_credentials
    Base64.strict_encode64([@email, @api_token].join(":"))
  end
end
