defmodule EmbedEx.Repo do
  use Ecto.Repo,
    otp_app: :embed_ex,
    adapter: Ecto.Adapters.Postgres
end
