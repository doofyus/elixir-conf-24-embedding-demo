defmodule EmbedEx.Indexing.Chunker do
  @moduledoc """
  Based on https://github.com/openai/chatgpt-retrieval-plugin/blob/main/services/chunks.py
  """

  # The target size of each text chunk in tokens
  @chunk_size 200
  # The minimum size of each text chunk in characters
  @chunk_chars_min 350
  # Discard chunks shorter than this
  @chunk_min_length 4
  # The maximum number of chunks to generate from a text
  @chunks_max 10000

  # ------ other recommended values ------
  # CHUNK_SIZE = 1024  # The target size of each text chunk in tokens
  # MIN_CHUNK_SIZE_CHARS = 350  # The minimum size of each text chunk in characters
  # MIN_CHUNK_LENGTH_TO_EMBED = 5  # Discard chunks shorter than this
  # EMBEDDINGS_BATCH_SIZE = 128  # The number of embeddings to request at a time
  # MAX_NUM_CHUNKS = 10000  # The maximum number of chunks to generate from a text

  def text_chunks(text, chunk_size \\ @chunk_size) do
    text_chunks_trimmed(String.trim(text), chunk_size)
  end

  # Return an empty list if the text is empty or whitespace
  defp text_chunks_trimmed("", _chunk_size), do: []

  defp text_chunks_trimmed(text, chunk_size) do
    # Tokenize the text
    {:ok, tokens} = Tiktoken.encode(model_tokenizer(), text)

    # Loop until all tokens are consumed while tokens and num_chunks < MAX_NUM_CHUNKS
    loop(tokens, chunk_size, 0, [])

    # TODO: Handle the remaining tokens
  end

  defp loop([], _chunk_size, _chunk_count, chunks), do: chunks

  defp loop(_tokens, _chunk_size, chunk_count, chunks) when chunk_count >= @chunks_max,
    do: chunks

  defp loop(tokens, chunk_size, chunk_count, chunks) do
    # Take the first chunk_size tokens as a chunk
    {chunk, rest} = Enum.split(tokens, chunk_size)

    # Decode the chunk into text
    {:ok, text} = Tiktoken.decode(model_tokenizer(), chunk)

    # Skip the chunk if it is empty or whitespace
    if String.trim(text) == "" do
      # Remove the tokens corresponding to the chunk text from the remaining tokens
      # Continue to the next iteration of the loop
      loop(rest, chunk_size, chunk_count, chunks)
    else
      text_clean =
        text
        |> check_punctuations()
        |> String.replace("\n", " ")
        |> String.trim()

      # Remove the tokens corresponding to the chunk text from the remaining tokens
      tokens_to_remove =
        Tiktoken.encode(model_tokenizer(), text_clean)
        |> elem(1)
        |> Enum.count()

      remaining_tokens = Enum.drop(tokens, tokens_to_remove)

      if String.length(text_clean) > @chunk_min_length do
        # Increment the number of chunks
        # Add the chunk to the list of chunks
        loop(remaining_tokens, chunk_size, chunk_count + 1, chunks ++ [text_clean])
      else
        # Continue to the next iteration of the loop
        loop(remaining_tokens, chunk_size, chunk_count, chunks)
      end
    end
  end

  defp check_punctuations(text) do
    # Find the last period or punctuation mark in the chunk
    reversed_text_chars =
      text
      |> String.codepoints()
      |> Enum.reverse()

    acc = {Enum.count(reversed_text_chars), nil}

    {index, last_punct} =
      Enum.reduce_while(reversed_text_chars, acc, fn char, {index, _} ->
        case char do
          "." -> {:halt, {index, char}}
          "!" -> {:halt, {index, char}}
          "?" -> {:halt, {index, char}}
          _ -> {:cont, {index - 1, nil}}
        end
      end)

    # If there is a punctuation mark, and the last punctuation index is before @chunk_chars_min
    # Truncate the chunk text at the punctuation mark
    if last_punct && index < @chunk_chars_min do
      text |> String.slice(0, index)
    else
      text
    end
  end

  # Models

  def model_tokenizer() do
    Application.get_env(:embed_ex, :models)[:tokenizer]
  end
end