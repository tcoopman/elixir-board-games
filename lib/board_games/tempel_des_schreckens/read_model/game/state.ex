defmodule BoardGames.TempelDesSchreckens.ReadModel.Game.State do
  use TypedStruct
  use Agent

  alias BoardGames.TempelDesSchreckens.Event
  alias BoardGames.TempelDesSchreckens.ReadModel.Game

  @type status :: :waiting_for_players | :can_be_started
  @type joining_status :: :has_capacity | :full

  typedstruct enforce: true do
    field :name, String.t(), default: nil
    field :status, status(), default: :waiting_for_players
    field :joining_status, joining_status(), default: :has_capacity
    field :game_id, String.t(), default: nil
    field :players, list(any()), default: []
  end

  def start_link(_) do
    Agent.start_link(fn -> %Game.State{} end)
  end

  def handle_event(pid, %Event.GameCreated{game_id: game_id, name: name} = _event) do
    Agent.update(pid, fn state ->
      %{state | game_id: game_id, name: name}
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

  def handle_event(pid, %Event.MaximumNumberOfPlayersJoined{} = _event) do
    Agent.update(pid, fn state ->
      %{state | joining_status: :full}
    end)
  end

  def get(game_id), do: Agent.get(pid(game_id), fn %Game.State{} = state -> state end)

  def allowed_actions(%Game.State{} = state, player_id) do
    {status, joining_status, players} = {state.status, state.joining_status, state.players}

    player_joined =
      Enum.any?(players, fn
        %{id: ^player_id} -> true
        _ -> false
      end)

    if player_joined do
      case status do
        :waiting_for_players -> [:cancel]
        :can_be_started -> [:cancel, :start]
      end
    else
      case joining_status do
        :has_capacity -> [:join]
        :full -> []
      end
    end
    |> MapSet.new()
  end

  defp pid(game_id) do
    {:ok, pid} = Game.Supervisor.state_by_game_id(game_id)
    pid
  end
end
