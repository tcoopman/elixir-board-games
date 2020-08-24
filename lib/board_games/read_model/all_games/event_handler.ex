defmodule BoardGames.ReadModel.AllGames.EventHandler do
  use Commanded.Event.Handler,
    application: BoardGames.App,
    name: "AllGames",
    subscription_opts: [transient: true]

  alias BoardGames.ReadModel.AllGames
  alias BoardGames.TempelDesSchreckens.Event

  def handle(%Event.GameCreated{} = event, _metadata) do
    AllGames.State.handle_event(event)
  end
end
