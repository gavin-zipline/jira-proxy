# frozen_string_literal: true

require "sinatra"
require "json"
require "dotenv/load"
require "base64"
require "rack/utils"
require_relative "jira_client"

set :bind, "0.0.0.0"
set :server, :puma
set :port, ENV.fetch("PORT", "4567").to_i

JIRA_CLIENT = JiraClient.new(
  base_url: ENV.fetch("JIRA_BASE_URL"),
  email: ENV.fetch("JIRA_EMAIL"),
  api_token: ENV.fetch("JIRA_API_TOKEN")
)

helpers do
  def json_response(status_code, body_hash)
    content_type :json
    status status_code
    JSON.pretty_generate(body_hash)
  end

  def authorized?
    provided_key = request.env["HTTP_X_API_KEY"].to_s
    expected_key = ENV.fetch("CHATGPT_API_KEY", "")
    return false if provided_key.empty? || expected_key.empty?
    return false unless provided_key.bytesize == expected_key.bytesize

    Rack::Utils.secure_compare(provided_key, expected_key)
  end

  def extract_description(value)
    text = collect_text(value).join(" ").gsub(/\s+/, " ").strip
    text.empty? ? nil : text
  end

  def extract_comment_body(value)
    extract_description(value)
  end

  private

  def collect_text(node)
    case node
    when String
      [node]
    when Array
      node.flat_map { |child| collect_text(child) }
    when Hash
      pieces = []
      pieces << node["text"] if node["text"].is_a?(String)
      pieces.concat(collect_text(node["content"])) if node.key?("content")
      pieces.concat(collect_text(node["body"])) if node.key?("body")
      pieces
    else
      []
    end
  end
end

before do
  halt json_response(401, { error: "Unauthorized" }) unless authorized?
end

get "/health" do
  json_response(200, { ok: true })
end

get "/issues/:key" do
  key = params[:key]

  issue = JIRA_CLIENT.get_issue(key)
  fields = issue.fetch("fields", {})

  comments = Array(fields.dig("comment", "comments")).map do |comment|
    {
      author: comment.dig("author", "displayName"),
      body: extract_comment_body(comment["body"]),
      created_at: comment["created"]
    }
  end

  normalized = {
    key: issue["key"] || key,
    summary: fields.dig("summary"),
    description: extract_description(fields["description"]),
    status: fields.dig("status", "name"),
    assignee: fields.dig("assignee", "displayName"),
    reporter: fields.dig("reporter", "displayName"),
    created_at: fields["created"],
    updated_at: fields["updated"],
    comments: comments
  }

  json_response(200, normalized)
rescue JiraClient::Error => e
  if e.status == 404
    json_response(404, { error: "Issue not found", key: key })
  else
    json_response(502, { error: "Error talking to Jira" })
  end
end
