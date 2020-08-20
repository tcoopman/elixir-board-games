defmodule BoardGames.ReadModel.AllGames do
  use TypedStruct

  use Commanded.Event.Handler,
    application: BoardGames.App,
    name: "AllGames",
    start_from: :origin,
    subscription_opts: [transient: true]

  alias BoardGames.TempelDesSchreckens.Event
  alias __MODULE__

  typedstruct enforce: true do
    field :in_progress, MapSet.t(String.t()), default: MapSet.new()
    field :waiting_for_players, MapSet.t(String.t()), default: MapSet.new()
    field :done, MapSet.t(String.t()), default: MapSet.new()
  end

  def init(config) do
    config = Keyword.put_new(config, :state, %AllGames{})

    {:ok, config}
  end

  def handle(%Event.GameCreated{game_id: game_id} = event, metadata) do
    %{state: state} = metadata
    state = %{state | waiting_for_players: MapSet.put(state.waiting_for_players, game_id)}
    IO.inspect(state)
    dispatch_event(event)
    {:ok, state}
  end

  defp dispatch_event(event) do
    Registry.dispatch(Registry.Events, :all_games, fn entries ->
      for {pid, _} <- entries, do: send(pid, {:event, event})
    end)
  end
end
