defmodule Indexing do
  alias Indexing.Tools.Chunker
  alias Indexing.Service

  # text-embedding-3-small	$0.00002 / 1K tokens
  # text-embedding-3-large	$0.00013 / 1K tokens
  # ada v2	$0.00010 / 1K tokens                  !! REQUIRED, OTHERS NOT SUPPORTED BY :tiktoken !!
  @model "text-embedding-ada-002"

  def run(path \\ "data/demo.txt") do
    path
    |> read_file
    |> chunk_file
    |> get_embeddings
    |> store_vectors
  end

  defp read_file(path) do
    File.read!(path)
  end

  defp chunk_file(content) do
    @model
    |> Chunker.text_chunks(content)
  end

  defp get_embeddings(chunks) do
    chunks
    |> Enum.map(&get_chunk_embedding/1)
  end

  defp get_chunk_embedding(chunk) do
    # TODO: input should be a list of strings (couldn't get it working)
    with {:ok, resp} <- OpenAI.embeddings(model: @model, input: chunk),
         %{usage: usage} <- resp,
         %{data: [%{"embedding" => embedding, "object" => "embedding"} | _]} <- resp do
      {chunk, embedding, usage}
    end
  end

  defp store_vectors(chunks) do
    chunks
    |> Enum.map(&store_chunk/1)
  end

  defp store_chunk({chunk, embedding, _usage}) do
    Service.create_chunk(chunk, embedding)
  end
end
