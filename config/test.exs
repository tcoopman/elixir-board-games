use Mix.Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :board_games, BoardGames.Repo,
  username: "postgres",
  password: "secret",
  database: "board_games_test#{System.get_env("MIX_TEST_PARTITION")}",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :board_games, BoardGamesWeb.Endpoint,
  http: [port: 4002],
  server: false

config :board_games, BoardGames.EventStore,
  serializer: Commanded.Serialization.JsonSerializer
config :board_games, BoardGames.App,
  event_store: [
    adapter: Commanded.EventStore.Adapters.InMemory,
    event_store: BoardGames.EventStore
  ],
  pubsub: :local,
  registry: :local

# Print only warnings and errors during test
config :logger, level: :warn
