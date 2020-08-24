defmodule BoardGames.ReadModel.AllGames.EventHandler do
  use Commanded.Event.Handler,
    application: BoardGames.App,
    name: "AllGames",
    subscription_opts: [transient: true]

  alias BoardGames.ReadModel.AllGames
  alias BoardGames.TempelDesSchreckens.Event

  def handle(%Event.GameCreated{} = event, _metadata) do
    :ok = AllGames.State.handle_event(event)

    Registry.dispatch(Registry.Events, :all_games, fn entries ->
      for {pid, _} <- entries, do: send(pid, {:all_games_updated, nil})
    end)
  end
end
