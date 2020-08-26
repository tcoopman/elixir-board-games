defmodule BoardGames.TempelDesSchreckens.ReadModel.Game.State do
  use TypedStruct
  use Agent

  alias BoardGames.TempelDesSchreckens.Event
  alias BoardGames.TempelDesSchreckens.ReadModel.Game

  @type status :: :waiting_for_players

  typedstruct enforce: true do
    field :status, status(), default: :waiting_for_players
    field :game_id, String.t(), default: nil
    field :players, list(any()), default: []
  end

  def start_link(_) do
    Agent.start_link(fn -> %Game.State{} end)
  end

  def handle_event(pid, %Event.GameCreated{game_id: game_id} = _event) do
    Agent.update(pid, fn state ->
      %{state | game_id: game_id}
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

  def status(game_id) do
    Agent.get(pid(game_id), fn %Game.State{status: status} ->
      status
    end)
  end

  def players(game_id) do
    Agent.get(pid(game_id), fn %Game.State{players: players} ->
      players
    end)
  end

  def allowed_actions(game_id, player_id) do
    {status, players} =
      Agent.get(pid(game_id), fn %Game.State{status: status, players: players} ->
        {status, players}
      end)

    player_joined =
      Enum.any?(players, fn
        %{id: ^player_id} -> true
        _ -> false
      end)

    case {status, player_joined} do
      {:waiting_for_players, false} -> [:join]
      _ -> []
    end
  end

  defp pid(game_id) do
    Game.Supervisor.state_by_game_id(game_id)
  end
end
