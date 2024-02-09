defmodule Querying do
  alias Indexing.Service

  @completion_model "gpt-3.5-turbo-0125"

  def run(prompt) do
    prompt
    |> get_embedding
    |> get_nearest_neighbours
    |> ask_llm
  end

  defp get_embedding(prompt) do
    with {:ok, resp} <- OpenAI.embeddings(model: Indexing.embedding_model(), input: prompt),
         %{usage: usage} <- resp,
         %{data: [%{"embedding" => embedding, "object" => "embedding"} | _]} <- resp do
      {prompt, embedding, usage}
    end
  end

  defp get_nearest_neighbours({prompt, embedding, _usage}) do
    case Service.nearest_neighbours(embedding) do
      [] -> {:error, "No nearest neighbours found"}
      neighbours -> {prompt, neighbours}
    end
  end

  defp ask_llm({prompt, neighbours}) do
    extra_info =
      neighbours
      |> Enum.map(&Map.get(&1, :text))
      |> Enum.join(" ")
      |> String.trim()

    query = """
    Use the below extra info on the Space Shuttle Challenger to answer the subsequent question. If the answer cannot be found, write "I don't know."

    Extra info:
    \"\"\"
    #{extra_info}
    \"\"\"

    Question: #{prompt}
    """

    messages = [
      %{role: "system", content: "You answer questions about the Space Shuttle Challenger."},
      %{role: "user", content: query}
    ]

    with {:ok, resp} <- OpenAI.chat_completion(model: @completion_model, messages: messages),
         %{choices: [%{"message" => %{"content" => answer}} | _]} <- resp do
      {prompt, answer}
    end
  end
end
