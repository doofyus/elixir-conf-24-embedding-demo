defmodule EmbedEx.Release do
  @moduledoc false

  def migrate do
    for repo <- repos() do
      {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :up, all: true))
    end
  end

  defp repos do
    Application.load(:embed_ex)
    Application.fetch_env!(:embed_ex, :ecto_repos)
  end
end
