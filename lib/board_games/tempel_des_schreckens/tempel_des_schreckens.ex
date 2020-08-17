defmodule BoardGames.TempelDesSchreckens do
  use TypedStruct

  alias __MODULE__

  typedstruct do
    field :game_id, String.t()
    field :players, list(String.t()), default: []
    field :name, String.t()
  end

  defguard is_non_empty_string?(str) when is_binary(str) and str != ""

  def execute(
        game,
        %BoardGames.TempelDesSchreckens.Command.CreateGame{} = command
      ) do
    game
    |> Commanded.Aggregate.Multi.new()
    |> Commanded.Aggregate.Multi.execute(&create_game(&1, command.game_id, command.name))
    |> Commanded.Aggregate.Multi.execute(&join_game(&1, command.player_id))
  end

  def execute(game, %BoardGames.TempelDesSchreckens.Command.JoinGame{player_id: player_id}),
    do: join_game(game, player_id)

  @spec apply(
          BoardGames.TempelDesSchreckens.t(),
          BoardGames.TempelDesSchreckens.Event.GameCreated.t()
        ) ::
          BoardGames.TempelDesSchreckens.t()
  def apply(%TempelDesSchreckens{} = game, %BoardGames.TempelDesSchreckens.Event.GameCreated{
        game_id: game_id,
        name: name
      }) do
    %{game | game_id: game_id, name: name}
  end

  def apply(
        %TempelDesSchreckens{players: players} = game,
        %BoardGames.TempelDesSchreckens.Event.JoinedGame{
          player_id: player_id
        }
      ) do
    %{game | players: [player_id | players]}
  end

  defp create_game(%TempelDesSchreckens{}, _, name) when not is_non_empty_string?(name),
    do: {:error, :invalid_name}

  defp create_game(%TempelDesSchreckens{players: []}, id, name) do
    %BoardGames.TempelDesSchreckens.Event.GameCreated{
      game_id: id,
      name: name
    }
  end

  defp join_game(%TempelDesSchreckens{game_id: game_id}, _)
       when not is_non_empty_string?(game_id),
       do: {:error, :game_is_not_in_progress}

  defp join_game(%TempelDesSchreckens{players: players}, _)
       when length(players) >= 10,
       do: {:error, :max_number_of_players_reached}

  defp join_game(%TempelDesSchreckens{} = game, player_id) do
    %BoardGames.TempelDesSchreckens.Event.JoinedGame{
      game_id: game.game_id,
      player_id: player_id
    }
  end
end
