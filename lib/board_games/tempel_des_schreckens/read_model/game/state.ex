defmodule BoardGames.TempelDesSchreckens.ReadModel.Game.State do
  use TypedStruct
  use Agent

  alias BoardGames.TempelDesSchreckens.Event
  alias __MODULE__

  @type status :: :waiting_for_players

  typedstruct enforce: true do
    field :status, status(), default: :waiting_for_players
    field :game_id, String.t(), default: nil
    field :players, list(any()), default: []
  end

  def start_link(_) do
    Agent.start_link(fn -> %State{} end, name: __MODULE__)
  end

  def handle_event(%Event.GameCreated{game_id: game_id} = _event) do
    Agent.update(__MODULE__, fn state ->
      %{state | game_id: game_id}
    end)
  end
  def handle_event(%Event.JoinedGame{player_id: player_id} = _event) do
    Agent.update(__MODULE__, fn state ->
      %{state | players: [player_id | state.players]}
    end)
  end

  def status() do
    Agent.get(__MODULE__, fn %State{status: status} ->
      status
    end)
  end

  def players() do
    Agent.get(__MODULE__, fn %State{players: players} ->
      players
    end)
  end

end
