defmodule Indexing.Chunk do
  use Ecto.Schema

  schema "chunks" do
    field(:embedding, Pgvector.Ecto.Vector)
    field(:text, :string)

    timestamps()
  end
end
