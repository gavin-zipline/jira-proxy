# jira-proxy

A tiny Sinatra service that proxies Jira Cloud issues for consumption by a Custom GPT Action. The service authenticates inbound requests using a shared API key and normalizes Jira issue payloads into a lightweight JSON structure suitable for ChatGPT.

## Environment Variables

Create a `.env` file (see below) with the following keys:

- `JIRA_BASE_URL` – Base URL for your Jira Cloud instance (e.g. `https://yourcompany.atlassian.net`).
- `JIRA_EMAIL` – Jira account email associated with the API token.
- `JIRA_API_TOKEN` – Jira API token generated for the account above.
- `CHATGPT_API_KEY` – Shared secret that inbound requests must provide via the `X-API-Key` header.
- `RACK_ENV` – Rack environment (defaults to `development`).
- `PORT` – Port to listen on locally (defaults to `4567`).

An example configuration is available in `.env.example`. Copy it and replace the placeholder values with your real credentials:

```bash
cp .env.example .env
```

## Local Development

1. Install dependencies:

   ```bash
   bundle install
   ```

2. Create your `.env` file as described above and ensure the values are correct.

3. Start the service with either command:

   ```bash
   bundle exec ruby app.rb
   ```

   or

   ```bash
   bundle exec rackup
   ```

4. Test the endpoint with `curl` (adjust the issue key and API key as needed):

   ```bash
   curl -H "X-API-Key: $CHATGPT_API_KEY" \
     "http://localhost:4567/issues/INT-530"
   ```

## Deployment

The project is ready for deployment on platforms like Heroku using the provided `Procfile` and Puma configuration. Configure the required environment variables in your hosting environment and run the web process:

```bash
web: bundle exec puma -C config/puma.rb
```

## Intended Usage

This service is designed to back a Custom GPT Action by providing a secure, normalized Jira issue payload over HTTP. Pair it with an OpenAPI specification that invokes the `/issues/{key}` endpoint with the `X-API-Key` header.
