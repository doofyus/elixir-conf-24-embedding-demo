defmodule Demo.MixProject do
  use Mix.Project

  def project do
    [
      app: :embed_ex,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {EmbedEx.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:tiktoken, "~> 0.2.0"},
      {:rustler, ">= 0.0.0", optional: true},
      {:ex_openai, "~> 1.5"},
      {:pgvector, "~> 0.2.0"},
      {:ecto_sql, "~> 3.5"},
      {:postgrex, ">= 0.0.0"}
    ]
  end
end
