require Protocol

Protocol.derive(Jason.Encoder, ExOpenAI.Components.ChatCompletionRequestUserMessage,
  only: [:content, :role]
)
