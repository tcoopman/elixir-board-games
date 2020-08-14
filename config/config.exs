# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :board_games,
  ecto_repos: [BoardGames.Repo]

# Configures the endpoint
config :board_games, BoardGamesWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "4VZX0rIn6/PTBQXncZ+BJ+VRSC6w26xSKDmO36URHAtBPAl5IPbJoKrFGarjDeYc",
  render_errors: [view: BoardGamesWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: BoardGames.PubSub,
  live_view: [signing_salt: "UfIVLFu8"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
