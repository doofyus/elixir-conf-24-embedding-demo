defmodule Indexing do
  def run(path \\ "data/demo.txt") do
    model = "text-embedding-ada-002"
    # model = "gpt-3.5-turbo"

    # 1. read file
    # 2. chunk file
    # 3. embed chunks
    # 4. store vectors
    path
    |> read_file()
    |> chunk_file(model)
  end

  defp read_file(path) do
    File.read!(path)
  end

  defp chunk_file(content, model) do
    model
    |> Chunker.text_chunks(content)
  end
end
