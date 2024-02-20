defmodule EmbedEx.Indexing.Chunker do
  @moduledoc """
  Based on https://github.com/openai/chatgpt-retrieval-plugin/blob/main/services/chunks.py
  """

  # The target size of each text chunk in tokens
  @chunk_size 200
  # The minimum size of each text chunk in chars
  @chunk_chars_min 350
  # Discard chunks shorter than this
  @chunk_min_length 5
  # The maximum number of chunks to generate from a text
  @chunks_max 10000

  # ------ other recommended values ------
  # CHUNK_SIZE = 1024  # The target size of each text chunk in tokens
  # MIN_CHUNK_SIZE_CHARS = 350  # The minimum size of each text chunk in chars
  # MIN_CHUNK_LENGTH_TO_EMBED = 5  # Discard chunks shorter than this
  # EMBEDDINGS_BATCH_SIZE = 128  # The number of embeddings to request at a time
  # MAX_NUM_CHUNKS = 10000  # The maximum number of chunks to generate from a text

  # Split a text into chunks of ~@chunk_size tokens, based on punctuation and newline boundaries.
  @spec text_chunks(String.t(), pos_integer()) :: {:ok, list(String.t())} | {:error, atom()}
  def text_chunks(text, chunk_size \\ @chunk_size)

  def text_chunks(text, chunk_size)
      when is_binary(text) and is_integer(chunk_size) and chunk_size > 0 do
    with :ok <- check_not_empty_or_whitespace(text),
         {:ok, clean_text} <- clean_text(text),
         {:ok, tokens} <- tokenize_text(clean_text) do
      create_chunks(tokens, chunk_size)
    end
  end

  def text_chunks(_, _), do: {:error, :invalid_input}

  defp create_chunks(tokens, chunk_size, chunks \\ []) do
    {chunk_tokens, rest_tokens} = Enum.split(tokens, chunk_size)

    with {:ok, chunk_text} <- detokenize_text(chunk_tokens),
         :ok <- check_not_empty_or_whitespace(chunk_text),
         {:ok, wrapped_text} <- wrap_text_by_sentence(chunk_text),
         {:ok, cleaned_text} <- clean_text(wrapped_text),
         {:ok, cleaned_text_tokens} <- tokenize_text(cleaned_text),
         {:ok, remaining_tokens} <- remaining_tokens(tokens, cleaned_text_tokens) do
      IO.inspect("remaining tokens: #{length(remaining_tokens)}")

      updated_chunks =
        case String.length(cleaned_text) > @chunk_min_length do
          true -> chunks ++ [cleaned_text]
          false -> chunks
        end

      check_chunks_count_and_continue(remaining_tokens, chunk_size, updated_chunks)
    else
      {:error, :empty_text} ->
        check_chunks_count_and_continue(rest_tokens, chunk_size, chunks)

      {:error, _} = error ->
        IO.inspect(error, label: "error1")
        error

      {[], asd} ->
        IO.inspect(asd, label: "asd")

      _ = error ->
        IO.inspect(error, label: "error2")
    end
  end

  defp check_chunks_count_and_continue(remaining_tokens, chunk_size, chunks) do
    case {remaining_tokens, length(chunks)} do
      {[_ | _] = tokens, num_chunks} when num_chunks < @chunks_max ->
        create_chunks(tokens, chunk_size, chunks)

      {[_ | _], num_chunks} when num_chunks >= @chunks_max ->
        # TODO: instead of ignoring the remaining tokens, return them
        IO.puts("Max chunks reached - ignoring the remaining tokens!")

        {:ok, chunks}

      _ ->
        {:ok, chunks}
    end
  end

  defp check_not_empty_or_whitespace(text) do
    case String.trim(text) != "" do
      true -> :ok
      false -> {:error, :empty_text}
    end
  end

  defp clean_text(text) do
    clean_text =
      text
      |> String.replace("\n\n", "\n")
      |> String.replace("\n", " ")
      |> String.replace("\r\r", "\r")
      |> String.replace("\r", " ")
      |> String.replace("    ", " ")
      |> String.replace("   ", " ")
      |> String.replace("  ", " ")
      |> String.trim()

    {:ok, clean_text}
  end

  defp detokenize_text(tokens) do
    Tiktoken.decode(model_tokenizer(), tokens)
  end

  defp tokenize_text(text) do
    Tiktoken.encode(model_tokenizer(), text)
  end

  defp remaining_tokens(tokens, cleaned_text_tokens) do
    remaining_tokens =
      tokens
      |> Enum.split(length(cleaned_text_tokens))
      |> elem(1)

    {:ok, remaining_tokens}
  end

  defp wrap_text_by_sentence(text) do
    chars = String.split(text, "", trim: true)

    output =
      chars
      |> Enum.reverse()
      |> Enum.find_index(fn c -> c == "." || c == "!" || c == "?" || c == "\n" end)
      |> case do
        nil ->
          text

        idx when idx < @chunk_chars_min and idx != 0 ->
          chars
          |> Enum.split(-idx)
          |> elem(0)
          |> Enum.join()

        _ ->
          text
      end

    {:ok, output}
  end

  # Models

  defp model_tokenizer() do
    Application.get_env(:embed_ex, :models)[:tokenizer]
  end
end
