# Demo

**TODO: Add description**

## Usage

#### Update the config

```
open config/config.exs
```
...and edit the file to match your configuration.

#### Update deps

```elixir
mix deps.get
```

#### Handle the DB

```elixir
docker-compose up -d

mix ecto.create
mix ecto.migrate
```

#### Run the app

```elixir
iex -S mix

EmbedEx.index <file_path>
EmbedEx.query <query>
```
