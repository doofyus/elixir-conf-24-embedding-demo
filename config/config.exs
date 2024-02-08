import Config

config :demo, Demo.Repo,
  database: "demo_db",
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  types: Indexing.PostgrexTypes

config :demo, ecto_repos: [Demo.Repo]

config :rustler_precompiled, :force_build, tiktoken: true

config :openai,
  # find it at https://platform.openai.com/account/api-keys
  api_key: "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",
  # find it at https://platform.openai.com/account/org-settings under "Organization ID"
  organization_key: "org-YWdRl2FzdkUeiZUMDf4Ooa00"

# # optional, use when required by an OpenAI API beta, e.g.:
# beta: "assistants=v1"

# # optional, passed to [HTTPoison.Request](https://hexdocs.pm/httpoison/HTTPoison.Request.html) options
# http_options: [recv_timeout: 30_000],

# # optional, useful if you want to do local integration tests using Bypass or similar
# # (https://github.com/PSPDFKit-labs/bypass), do not use it for production code,
# # but only in your test config!
# api_url: "http://localhost/"
