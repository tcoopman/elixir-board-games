defmodule BoardGames.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      BoardGames.Repo,
      # Start the Telemetry supervisor
      BoardGamesWeb.Telemetry,
      # EventStore
      {Registry, keys: :duplicate, name: Registry.Events},
      BoardGames.App,

      # Start the PubSub system
      {Phoenix.PubSub, name: BoardGames.PubSub},
      # Start the Endpoint (http/https)
      # Readmodels
      BoardGames.ReadModel.AllGames.State,
      BoardGames.ReadModel.AllGames.EventHandler,
      BoardGames.TempelDesSchreckens.ReadModel.Game.State,

      BoardGamesWeb.Endpoint
      # Start a worker by calling: BoardGames.Worker.start_link(arg)
      # {BoardGames.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: BoardGames.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    BoardGamesWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
