defmodule BoardGames.ReadModel.AllGames.State do
  use TypedStruct
  use Agent

  alias BoardGames.TempelDesSchreckens.Event
  alias __MODULE__

  typedstruct enforce: true do
    field :waiting_for_players, Map.t(String.t(), any()), default: Map.new()
  end

  def start_link(_) do
    Agent.start_link(fn -> %State{} end, name: __MODULE__)
  end

  def handle_event(%Event.GameCreated{} = event) do
    Agent.update(__MODULE__, fn state ->
      waiting_for_players = Map.put_new(state.waiting_for_players, event.game_id, event.name)
      %{state | waiting_for_players: waiting_for_players}
    end)
  end

  def waiting_for_players() do
    Agent.get(__MODULE__, fn %State{waiting_for_players: waiting_for_players} ->
      Map.values(waiting_for_players)
    end)
  end
end
