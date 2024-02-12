defmodule EmbedEx.Database.Service do
  import Ecto.Query
  import Pgvector.Ecto.Query

  alias EmbedEx.Repo
  alias EmbedEx.Database.Schema

  # TODO: store all the embeddings in a single transaction (so if smth fails, nothing is stored)
  def store_embedding(text, embedding) do
    Repo.insert(%Schema{text: text, embedding: embedding})
  end

  def nearest_neighbours(embedding, k \\ 5) do
    Repo.all(from(c in Schema, order_by: l2_distance(c.embedding, ^embedding), limit: ^k))
  end

  def wipe() do
    Repo.delete_all(Schema)
  end
end
