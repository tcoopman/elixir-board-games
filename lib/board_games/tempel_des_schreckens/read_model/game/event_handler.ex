defmodule BoardGames.TempelDesSchreckens.ReadModel.Game.EventHandler do
  use Commanded.Event.Handler,
    application: BoardGames.App,
    subscription_opts: [transient: true]

  alias BoardGames.TempelDesSchreckens.Event
  alias BoardGames.TempelDesSchreckens.ReadModel.Game.State

  def init(config) do
    {game_id, config} = Keyword.pop!(config, :game_id)

    config =
      config
      |> Keyword.put(:name, Module.concat(__MODULE__, game_id))
      |> Keyword.put(:subscribe_to, game_id)

    {:ok, config}
  end

  def handle(%Event.GameCreated{} = event, _metadata) do
    :ok = State.handle_event(event)
  end

  def handle(%Event.JoinedGame{} = event, _metadata) do
    :ok = State.handle_event(event)
  end
end
