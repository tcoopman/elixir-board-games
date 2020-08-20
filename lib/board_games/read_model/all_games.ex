defmodule BoardGames.ReadModel.AllGames do
  use TypedStruct
  use GenServer

  alias BoardGames.TempelDesSchreckens.Event
  alias __MODULE__

  typedstruct enforce: true do
    field :in_progress, MapSet.t(String.t()), default: MapSet.new()
    field :waiting_for_players, MapSet.t(String.t()), default: MapSet.new()
    field :done, MapSet.t(String.t()), default: MapSet.new()
    field :subscription, pid(), default: nil
  end

  def start_link(default) do
    GenServer.start_link(__MODULE__, default)
  end

  @impl true
  def init(_config) do
    {:ok, %AllGames{}, {:continue, :subscribe}}
  end

  @impl true
  def handle_info({:events, events}, state) do
    state =
      Enum.reduce(events, state, fn
        %EventStore.RecordedEvent{data: %Event.GameCreated{game_id: game_id}}, state ->
          %{state | waiting_for_players: MapSet.put(state.waiting_for_players, game_id)}

        %EventStore.RecordedEvent{data: _}, state ->
          state
      end)

    :ok = BoardGames.EventStore.ack(state.subscription, events)

    dispatch_update(state)
    {:noreply, state}
  end

  @impl true
  def handle_info({:subscribed, _subscription}, state) do
    {:noreply, state}
  end

  defp dispatch_update(state) do
    all_games = %{
      in_progress: state.in_progress,
      waiting_for_players: state.waiting_for_players,
      done: state.done
    }

    Registry.dispatch(Registry.Events, :all_games, fn entries ->
      for {pid, _} <- entries, do: send(pid, {:all_games_updated, all_games})
    end)
  end

  @impl true
  def handle_continue(:subscribe, state) do
    {:ok, subscription} =
      BoardGames.EventStore.subscribe_to_all_streams(__MODULE__, self(),
        start_from: :origin,
        transient: true
      )

    state = %{state | subscription: subscription}
    {:noreply, state}
  end
end
