defmodule EmbedEx.Querying.Service do
  alias EmbedEx.Database.Service, as: Database
  alias EmbedEx.Openai.Service, as: Openai

  alias ExOpenAI.Components.CreateChatCompletionResponse, as: ChatResponse
  alias ExOpenAI.Components.ChatCompletionRequestSystemMessage, as: SystemMessage
  alias ExOpenAI.Components.ChatCompletionRequestUserMessage, as: UserMessage

  def run(prompt, query_expansion \\ false) do
    prompt
    |> expand_queries(query_expansion)
    |> create_embeddings()
    |> get_nearest_neighbours()
    |> query_llm()
  end

  # Query expansion
  defp expand_queries(prompt, false), do: {:ok, [prompt]}

  defp expand_queries(prompt, true) do
    with {:ok, %ChatResponse{} = resp} <-
           Openai.chat_completion(query_messages_expand_query(prompt)),
         %{choices: [%{message: %{content: answer}} | _]} <- resp,
         %{usage: %{total_tokens: total_tokens}} <- resp do
      IO.inspect("- query expansion successful, total tokens: #{total_tokens}")

      prompts =
        ([prompt] ++ extract_extra_queries(answer))
        |> clean_prompts()

      {:ok, prompts}
    else
      err ->
        {:error, err}
    end
  end

  # Embeddings
  defp create_embeddings({:ok, [nil]}), do: {:error, :missing_prompt}
  defp create_embeddings({:ok, [""]}), do: {:error, :missing_prompt}

  defp create_embeddings({:ok, prompts}) do
    prompts
    |> Enum.map(&create_embedding/1)
  end

  defp create_embeddings(error), do: error

  defp create_embedding(prompt) do
    case Openai.embeddings(prompt) do
      {:ok, embedding} ->
        IO.inspect("- embedding successful: #{prompt}")

        {:ok, {prompt, embedding}}

      err ->
        err
    end
  end

  # Nearest neighbours
  defp get_nearest_neighbours([]), do: {:error, :no_embeddings}

  defp get_nearest_neighbours(prompt_embeddings) do
    prompt_embeddings
    |> Enum.map(&get_nearest_neighbours_for_embedding/1)
    |> Enum.flat_map(&flat_map_nearest_neighbours/1)
  end

  defp get_nearest_neighbours_for_embedding({:ok, {prompt, embedding}}) do
    case Database.nearest_neighbours(embedding) do
      [] ->
        {:error, {:no_neighbours, prompt}}

      neighbours ->
        IO.inspect(
          "- nearest neighbours successful: #{prompt}, #{Enum.count(neighbours)} neighbours"
        )

        {:ok, {prompt, neighbours}}
    end
  end

  defp get_nearest_neighbours_for_embedding(error), do: error

  defp flat_map_nearest_neighbours({:ok, {prompt, neighbours}}) do
    neighbours
    |> Enum.map(fn neighbour -> {:ok, {prompt, neighbour}} end)
  end

  defp flat_map_nearest_neighbours({:error, {:no_neighbours, prompt}}),
    do: [{:ok, {prompt, %{text: ""}}}]

  defp flat_map_nearest_neighbours(error), do: [error]

  # Actual LLM query
  defp query_llm([]), do: {:error, :no_data}

  defp query_llm(data) do
    extra_information =
      data
      |> Enum.filter(&filter_ok_neighbours/1)
      |> Enum.map(&extract_neighbours_text/1)
      |> Enum.uniq()
      |> Enum.join("\n")

    {[main_prompt], other_prompts} =
      data
      |> Enum.filter(&filter_ok_neighbours/1)
      |> Enum.map(&extract_neighbours_prompts/1)
      |> Enum.uniq()
      |> Enum.split(1)

    query = query_input(main_prompt, Enum.join(other_prompts, "\n"), extra_information)

    IO.inspect("- querring LLM...")

    with {:ok, %ChatResponse{} = resp} <- Openai.chat_completion(query_messages(query)),
         %{choices: [%{message: %{content: answer}} | _]} <- resp,
         %{usage: %{total_tokens: total_tokens}} <- resp do
      IO.inspect("- query successful, total tokens: #{total_tokens}")

      {:ok, answer}
    end
  end

  # Helpers
  defp clean_prompts(queries) do
    queries
    |> Enum.map(&String.trim/1)
    |> Enum.filter(&(&1 != ""))
    |> Enum.filter(&(&1 != nil))
    |> Enum.filter(&(&1 != "null"))
    |> Enum.filter(&(&1 != "\""))
  end

  defp extract_extra_queries(content) do
    content
    |> String.split("\n")
    |> Enum.map(&String.trim/1)
  end

  defp extract_neighbours_text({:ok, {_prompt, %{text: text}}}), do: String.trim(text)
  defp extract_neighbours_text(error), do: error

  defp extract_neighbours_prompts({:ok, {prompt, _}}), do: prompt
  defp extract_neighbours_prompts(error), do: error

  defp filter_ok_neighbours({:ok, _}), do: true
  defp filter_ok_neighbours(_), do: false

  defp query_input(main_prompt, other_prompts, extra_information) do
    """
    Extra information:
    \"\"\"
    #{extra_information}
    \"\"\"

    Main Question:
    #{main_prompt}

    Extra Questions:
    #{other_prompts}
    """
  end

  # Messages
  defp query_messages(query) do
    [
      %SystemMessage{
        role: :system,
        content: """
        You are a helpful expert research assistant.
        You will be shown the user's question, and the relevant information for the topic. Answer the user's question using only this information.
        Provide a consice and complete answer to the user's main question. Keep it short and on point.
        Do not include any additional information that is not relevant to the user's question. Also don't mention the input information.
        Do not pose any rethorical questions to the user in the response, but just answer directly. Don't start with a question!
        Your main goal is to answer the main question, never mention that there are different questions.
        If you can't answer some questions (except the main one), just leave them out.
        """
      },
      %UserMessage{role: :user, content: query}
    ]
  end

  defp query_messages_expand_query(query) do
    [
      %SystemMessage{
        role: :system,
        content: """
        You are a helpful expert research assistant.
        Suggest up to five additional related questions to help find the information needed, for the provided question.
        Suggest only short questions without compound sentences. Suggest a variety of questions that cover different aspects of the topic.
        Make sure they are complete questions, and that they are related to the original question.
        Output one question per line. Do not number the questions. Do not add a line infront.
        """
      },
      %UserMessage{role: :user, content: query}
    ]
  end
end
