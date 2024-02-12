import Config

config :embed_ex, EmbedEx.Repo,
  url: System.fetch_env!("DATABASE_URL"),
  types: EmbedEx.PostgrexTypes

config :embed_ex, ecto_repos: [EmbedEx.Repo]

config :rustler_precompiled, :force_build, tiktoken: true

config :embed_ex, :models,
  embedding: System.fetch_env!("MODEL_EMBEDDING"),
  tokenizer: System.fetch_env!("MODEL_TOKENIZER"),
  completion: System.fetch_env!("MODEL_COMPLETION")

config :ex_openai,
  # find it at https://platform.openai.com/account/api-keys
  api_key: System.fetch_env!("OPENAI_API_KEY"),
  # find it at https://platform.openai.com/account/api-keys
  organization_key: System.fetch_env!("OPENAI_ORGANIZATION_KEY"),
  # optional, passed to [HTTPoison.Request](https://hexdocs.pm/httpoison/HTTPoison.Request.html) options
  http_options: [recv_timeout: 50_000]

# optional, default request headers. The following header is required for Assistant endpoints, which are in beta as of December 2023.
# http_headers: [
#   {"OpenAI-Beta", "assistants=v1"}
# ]
