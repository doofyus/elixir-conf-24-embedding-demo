defmodule EmbedEx do
  @moduledoc """
  Tool to create embeddings (vectors) for data, store them in a PSQL (with vector extension)
  and enhance querying with the embeddings.
  """

  alias EmbedEx.Indexing.Service, as: Indexing
  alias EmbedEx.Querying.Service, as: Querying

  @spec index(String.t()) :: :ok | {:error, atom()}
  def index(file_path \\ "data/demo.txt") do
    Indexing.run(file_path)
  end

  @spec query(String.t(), boolean()) :: {:ok, String.t()} | {:error, atom()}
  def query(prompt, query_expansion \\ false) do
    Querying.run(prompt, query_expansion)
  end
end
