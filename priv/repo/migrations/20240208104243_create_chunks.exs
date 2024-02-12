defmodule EmbedEx.Repo.Migrations.CreateChunks do
  use Ecto.Migration

  def change do
    create table(:chunks) do
      add :embedding, :vector, size: 1536
      add :text, :text

      timestamps()
    end
  end
end
