# Demo

**TODO: Add description**

## Usage

#### Set the environment variables

```bash
export DATABASE_URL="ecto://postgres:postgres@localhost/demo_db"

export MODEL_EMBEDDING="text-embedding-3-small"
export MODEL_TOKENIZER="text-embedding-ada-002"
export MODEL_COMPLETION="gpt-3.5-turbo-0125"

export OPENAI_API_KEY="<openai_key>"
export OPENAI_ORGANIZATION_KEY="<openai-org>"
```

#### Get the DB up and running

```bash
docker-compose up -d
```

### Option #1
Recommended for Elixir devs.

```elixir
mix deps.get

mix ecto.create
mix ecto.migrate

iex -S mix

EmbedEx.index <file_path>
EmbedEx.query <query>
```

### Option #2
For non-Elixir devs.

```
release/embed_ex/bin/embed_ex eval "EmbedEx.Release.migrate"
release/embed_ex/bin/embed_ex start_iex

EmbedEx.index <file_path>
EmbedEx.query <query>
```