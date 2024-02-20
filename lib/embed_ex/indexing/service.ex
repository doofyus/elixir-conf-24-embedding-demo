defmodule EmbedEx.Indexing.Service do
  alias EmbedEx.Database.Service, as: DBService
  alias EmbedEx.Indexing.Chunker
  alias EmbedEx.Openai.Service, as: Openai

  @spec run(String.t()) :: :ok | {:error, atom()}
  def run(file_path) do
    file_path
    |> read_file
    |> chunk_file
    |> get_embeddings
    |> store_vectors
  end

  defp read_file(nil), do: {:error, :missing_file}
  defp read_file(""), do: {:error, :missing_file}

  defp read_file(file_path) do
    result = File.read(file_path)

    case result do
      {:ok, _content} -> IO.inspect("- file read successfully")
      {:error, _reason} -> IO.inspect("- file read failed")
    end

    result
  end

  defp chunk_file({:ok, file_content}) do
    {:ok, chunks} = Chunker.text_chunks(file_content)

    IO.inspect("- file chunked successfully (#{length(chunks)} chunks)")

    {:ok, chunks}
  end

  defp chunk_file(error), do: error

  defp get_embeddings({:ok, chunks}) do
    result = Openai.embeddings(chunks)

    case result do
      {:ok, chunks_embeddings, total_tokens} ->
        IO.inspect(
          "- embeddings fetched successfully (#{length(chunks_embeddings)} embeddings), total tokens: #{total_tokens}"
        )

      {:error, _reason} ->
        IO.inspect("- embeddings fetch failed")
    end

    result
  end

  defp get_embeddings(error), do: error

  defp store_vectors({:ok, [], _total}), do: {:error, :no_embeddings}

  defp store_vectors({:ok, chunks_embeddings, _total}) do
    result =
      Enum.reduce_while(chunks_embeddings, :ok, fn {chunk, embedding}, acc ->
        case DBService.store_embedding(chunk, embedding) do
          {:ok, _schema} ->
            {:cont, acc}

          {:error, _changeset} ->
            {:error, :db_error}
        end
      end)

    case result do
      :ok -> IO.inspect("- embeddings stored successfully")
      :error -> IO.inspect("- embeddings store failed")
    end

    result
  end

  defp store_vectors(error), do: error
end
