defmodule BoardGames.TempelDesSchreckens.ReadModel.Game.State do
  use TypedStruct
  use Agent

  alias BoardGames.TempelDesSchreckens.Event
  alias BoardGames.TempelDesSchreckens.ReadModel.Game

  @type status :: :waiting_for_players | :can_be_started | :playing

  typedstruct enforce: true do
    field :game_id, String.t(), default: nil
    field :name, String.t(), default: nil
    field :status, status(), default: :waiting_for_players
    field :accepting_players, boolean(), default: false
    field :players, Map.t(String.t(), BoardGames.ReadModel.Player.t()), default: Map.new()
    field :player_with_key, String.t(), default: nil
    field :current_round, pos_integer(), default: nil
    field :rooms, Map.t(String.t(), {atom(), atom()}), default: Map.new()
    field :roles, Map.t(String.t(), atom()), default: Map.new()
  end

  defmodule PublicPlayerState do
    use TypedStruct

    typedstruct enforce: true do
      field :id, String.t()
      field :has_key, boolean(), default: false
      field :rooms, list(atom()), default: []
    end
  end

  defmodule PrivatePlayerState do
    use TypedStruct

    typedstruct enforce: true do
      field :id, String.t()
      field :role, atom()
      field :treasures, pos_integer()
      field :traps, pos_integer()
      field :empties, pos_integer()
      field :can_open_room, boolean()
    end
  end

  def start_link(_) do
    Agent.start_link(fn -> %Game.State{} end)
  end

  def handle_event(pid, %Event.GameCreated{game_id: game_id, name: name} = _event) do
    Agent.update(pid, fn state ->
      %{
        state
        | game_id: game_id,
          name: name,
          accepting_players: true
      }
    end)
  end

  def handle_event(pid, %Event.JoinedGame{player_id: player_id} = _event) do
    Agent.update(pid, fn state ->
      player_info =
        with {:ok, player} <- BoardGames.ReadModel.Players.by_id(player_id) do
          player
        else
          {:error, :not_found} ->
            %BoardGames.ReadModel.Player{
              id: player_id,
              name: "User does not exist",
              bio: "A John Doe, a ghost of GDPR?",
              picture_url:
                "https://images.unsplash.com/photo-1501871732394-eccc65227089?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=facearea&facepad=2&w=256&h=256&q=80"
            }
        end

      %{state | players: Map.put(state.players, player_id, player_info)}
    end)
  end

  def handle_event(pid, %Event.GameCanBeStarted{} = _event) do
    Agent.update(pid, fn state ->
      %{state | status: :can_be_started}
    end)
  end

  def handle_event(pid, %Event.GameStarted{} = _event) do
    Agent.update(pid, fn state ->
      %{
        state
        | status: :playing,
          accepting_players: false
      }
    end)
  end

  def handle_event(pid, %Event.RolesDealt{roles: roles} = _event) do
    Agent.update(pid, fn state ->
      roles =
        Enum.map(roles, fn
          {player_id, "adventurer"} -> {player_id, :adventurer}
          {player_id, "guardian"} -> {player_id, :guardian}
        end)
        |> Map.new()

      %{state | roles: roles}
    end)
  end

  def handle_event(pid, %Event.ReceivedKey{player_id: player_id} = _event) do
    Agent.update(pid, fn state ->
      %{state | player_with_key: player_id}
    end)
  end

  def handle_event(pid, %Event.RoundStarted{} = _event) do
    Agent.update(pid, fn
      %{current_round: nil} = state ->
        %{state | current_round: 1}

      %{current_round: current_round} = state ->
        %{state | current_round: current_round + 1}
    end)
  end

  def handle_event(pid, %Event.RoomsDealt{rooms: rooms} = _event) do
    Agent.update(pid, fn state ->
      rooms =
        Enum.map(rooms, fn {player_id, rooms} ->
          {player_id,
           Enum.map(rooms, fn
             "treasure" -> {:treasure, :closed}
             "empty" -> {:empty, :closed}
             "trap" -> {:trap, :closed}
           end)}
        end)
        |> Map.new()

      %{state | rooms: rooms}
    end)
  end

  def handle_event(pid, %Event.MaximumNumberOfPlayersJoined{} = _event) do
    Agent.update(pid, fn state ->
      %{state | accepting_players: false}
    end)
  end

  def get(game_id, player_id) do
    state =
      Agent.get(pid(game_id), fn %Game.State{} = state ->
        state
      end)

    {state_of_players, private} =
      if state.status == :playing and Map.has_key?(state.players, player_id) do
        {Enum.map(Map.keys(state.players), fn player_id ->
           calculate_player_state(state, player_id)
         end), calculate_private(state, player_id)}
      else
        {nil, nil}
      end

    %{
      game_id: game_id,
      name: state.name,
      status: state.status,
      accepting_players: state.accepting_players,
      current_round: state.current_round,
      joined_players: state.players,
      allowed_actions: allowed_actions(state, player_id),
      state_of_players: state_of_players,
      private: private
    }
  end

  defp calculate_private(%Game.State{} = state, player_id) do
    {treasures, traps, empties} =
      Map.get(state.rooms, player_id, [])
      |> Enum.reduce({0, 0, 0}, fn
        {:treasure, _}, {treasures, traps, empties} -> {treasures + 1, traps, empties}
        {:trap, _}, {treasures, traps, empties} -> {treasures, traps + 1, empties}
        {:empty, _}, {treasures, traps, empties} -> {treasures, traps, empties + 1}
      end)

    %PrivatePlayerState{
      id: player_id,
      role: Map.get(state.roles, player_id, nil),
      treasures: treasures,
      traps: traps,
      empties: empties,
      can_open_room: player_id == state.player_with_key
    }
  end

  defp calculate_player_state(state, player_id) do
    rooms =
      Map.get(state.rooms, player_id, [])
      |> Enum.map(fn
        {_, :closed} -> :closed
        {room, :open} -> room
      end)

    %PublicPlayerState{
      id: player_id,
      has_key: player_id == state.player_with_key,
      rooms: rooms
    }
  end

  defp allowed_actions(
         %Game.State{status: status, accepting_players: accepting_players, players: players} =
           state,
         player_id
       ) do
    player_joined = Map.has_key?(players, player_id)

    if player_joined do
      cond do
        status == :waiting_for_players ->
          [:cancel]

        status == :can_be_started ->
          [:cancel, :start]

        status == :playing && state.current_round == nil ->
          []

        true ->
          []
      end
    else
      if accepting_players do
        [:join]
      else
        []
      end
    end
    |> MapSet.new()
  end

  defp pid(game_id) do
    {:ok, pid} = Game.Supervisor.state_by_game_id(game_id)
    pid
  end
end
