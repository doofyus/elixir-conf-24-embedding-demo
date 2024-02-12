import Config

config :embed_ex, EmbedEx.Repo,
  database: "demo_db",
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  types: EmbedEx.PostgrexTypes

config :embed_ex, ecto_repos: [EmbedEx.Repo]

config :rustler_precompiled, :force_build, tiktoken: true

config :embed_ex, :models,
  embedding: "text-embedding-3-small",
  tokenizer: "text-embedding-ada-002",
  completion: "gpt-3.5-turbo-0125"

config :ex_openai,
  # find it at https://platform.openai.com/account/api-keys
  api_key: "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",
  # find it at https://platform.openai.com/account/api-keys
  organization_key: "org-vtbtvgwIlQPHRs6excCcDqYm",
  # optional, passed to [HTTPoison.Request](https://hexdocs.pm/httpoison/HTTPoison.Request.html) options
  http_options: [recv_timeout: 50_000]

# optional, default request headers. The following header is required for Assistant endpoints, which are in beta as of December 2023.
# http_headers: [
#   {"OpenAI-Beta", "assistants=v1"}
# ]
