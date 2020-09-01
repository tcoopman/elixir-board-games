defmodule BoardGames.TempelDesSchreckens.ReadModel.Game.State do
  use TypedStruct
  use Agent

  alias BoardGames.TempelDesSchreckens.Event
  alias BoardGames.TempelDesSchreckens.ReadModel.Game

  @type status :: :waiting_for_players | :can_be_started | :playing

  typedstruct enforce: true do
    field :name, String.t(), default: nil
    field :status, status(), default: :waiting_for_players
    field :accepting_players, boolean(), default: false
    field :game_id, String.t(), default: nil
    field :players, list(any()), default: []
    field :player_with_key, String.t(), default: nil
    field :current_round, pos_integer(), default: nil
  end

  def start_link(_) do
    Agent.start_link(fn -> %Game.State{} end)
  end

  def handle_event(pid, %Event.GameCreated{game_id: game_id, name: name} = _event) do
    Agent.update(pid, fn state ->
      %{state | game_id: game_id, name: name, accepting_players: true}
    end)
  end

  def handle_event(pid, %Event.JoinedGame{player_id: player_id} = _event) do
    Agent.update(pid, fn state ->
      player =
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

      %{state | players: [player | state.players]}
    end)
  end

  def handle_event(pid, %Event.GameCanBeStarted{} = _event) do
    Agent.update(pid, fn state ->
      %{state | status: :can_be_started}
    end)
  end

  def handle_event(pid, %Event.GameStarted{} = _event) do
    Agent.update(pid, fn state ->
      %{state | status: :playing, accepting_players: false}
    end)
  end

  def handle_event(_pid, %Event.RolesDealt{} = _event) do
    :ok
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

  def handle_event(_pid, %Event.RoomsDealt{} = _event) do
    :ok
  end

  def handle_event(pid, %Event.MaximumNumberOfPlayersJoined{} = _event) do
    Agent.update(pid, fn state ->
      %{state | accepting_players: false}
    end)
  end

  def get(game_id), do: Agent.get(pid(game_id), fn %Game.State{} = state -> state end)

  def allowed_actions(%Game.State{} = state, player_id) do
    {status, accepting_players, players} = {state.status, state.accepting_players, state.players}

    player_joined =
      Enum.any?(players, fn
        %{id: ^player_id} -> true
        _ -> false
      end)

    if player_joined do
      cond do
        status == :waiting_for_players ->
          [:cancel]

        status == :can_be_started ->
          [:cancel, :start]

        status == :playing && state.current_round == nil ->
          []

        status == :playing && player_id == state.player_with_key ->
          [:open_room]

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
