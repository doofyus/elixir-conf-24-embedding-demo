defmodule EmbedEx.Querying.Service do
  alias EmbedEx.Database.Service, as: Database
  alias EmbedEx.Openai.Service, as: Openai

  alias ExOpenAI.Components.CreateChatCompletionResponse, as: ChatResponse
  alias ExOpenAI.Components.ChatCompletionRequestUserMessage, as: UserMessage

  def run(prompt) do
    prompt
    |> create_embedding
    |> get_nearest_neighbours
    |> query_llm
  end

  defp create_embedding(nil), do: {:error, :missing_prompt}
  defp create_embedding(""), do: {:error, :missing_prompt}

  defp create_embedding(prompt) do
    case Openai.embeddings(prompt) do
      {:ok, embedding} ->
        IO.inspect("- embedding created successfully")

        {:ok, {prompt, embedding}}

      {:error, _reason} = error ->
        IO.inspect("- embedding creation failed")

        error
    end
  end

  defp get_nearest_neighbours({:ok, {prompt, embedding}}) do
    case Database.nearest_neighbours(embedding) do
      [] ->
        IO.inspect("- nearest neighbours fetch failed")

        {:error, :no_neighbours}

      neighbours ->
        IO.inspect("- nearest neighbours fetched successfully (#{length(neighbours)} neighbours)")

        {:ok, {prompt, neighbours}}
    end
  end

  defp get_nearest_neighbours(error), do: error

  defp query_llm({:ok, {prompt, neighbours}}) do
    extra_info = query_extra_info(neighbours)
    query = query_input(prompt, extra_info)

    with {:ok, %ChatResponse{} = resp} <- Openai.chat_completion(query_messages(query)),
         %{choices: [%{message: %{content: answer}} | _]} <- resp,
         %{usage: %{total_tokens: total_tokens}} <- resp do
      IO.inspect("- chat completion successful, total tokens: #{total_tokens}")

      {:ok, answer}
    else
      err ->
        IO.inspect("- chat completion failed")

        {:error, err}
    end
  end

  defp query_llm(error), do: error

  # Helpers

  defp query_extra_info(neighbours) do
    neighbours
    |> Enum.map(&Map.get(&1, :text))
    |> Enum.join(" ")
    |> String.trim()
  end

  defp query_input(prompt, extra_info) do
    """
    Use the below extra info to answer the subsequent question.
    If the answer cannot be found, write "I don't know."

    Extra info:
    \"\"\"
    #{extra_info}
    \"\"\"

    Question: #{prompt}
    """
  end

  defp query_messages(query) do
    [
      %UserMessage{role: :user, content: query}
    ]
  end
end
