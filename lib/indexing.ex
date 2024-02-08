defmodule Indexing do
  alias Tools.Chunker

  # text-embedding-3-small	$0.00002 / 1K tokens
  # text-embedding-3-large	$0.00013 / 1K tokens
  # ada v2	$0.00010 / 1K tokens
  @model "text-embedding-ada-002"

  def run(path \\ "data/demo.txt") do
    # 1. read file
    # 2. chunk file
    # 3. embed chunks
    # 4. store vectors
    path
    |> read_file
    |> chunk_file
    |> get_embeddings
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
    with {:ok, resp} <- OpenAI.embeddings(model: @model, input: chunk),
         %{usage: usage} <- resp,
         %{data: [%{"embedding" => embedding, "object" => "embedding"} | _]} <- resp do
      IO.inspect(usage, label: "Usage")

      {chunk, embedding}
    end
  end
end
