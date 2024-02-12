defmodule EmbedEx.Openai.Service do
  alias ExOpenAI.Components.CreateEmbeddingResponse

  def chat_completion(messages) do
    ExOpenAI.Chat.create_chat_completion(messages, model_completion())
  end

  def embeddings(input) when is_bitstring(input) do
    with {:ok, %CreateEmbeddingResponse{} = resp} <-
           ExOpenAI.Embeddings.create_embedding(input, model_embedding()),
         %{data: [%{embedding: embedding}]} <- resp do
      {:ok, embedding}
    end
  end

  def embeddings(input) when is_list(input) do
    with {:ok, %CreateEmbeddingResponse{} = resp} <-
           ExOpenAI.Embeddings.create_embedding(input, model_embedding()),
         %{data: embeddings, usage: %{total_tokens: total_tokens}} <- resp do
      {:ok,
       Enum.map(embeddings, fn obj ->
         {Enum.at(input, obj.index), obj.embedding}
       end), total_tokens}
    end
  end

  # Models

  def model_completion() do
    Application.get_env(:embed_ex, :models)[:completion]
  end

  def model_embedding() do
    Application.get_env(:embed_ex, :models)[:embedding]
  end
end
