defmodule Indexing.Service do
  import Ecto.Query
  import Pgvector.Ecto.Query

  alias Demo.Repo
  alias Indexing.Chunk

  def create_chunk(text, embedding) do
    Repo.insert!(%Chunk{text: text, embedding: embedding})
  end

  def nearest_neighbors(embedding, k \\ 5) do
    Repo.all(from(c in Chunk, order_by: l2_distance(c.embedding, ^embedding), limit: ^k))
  end
end