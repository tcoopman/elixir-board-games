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
        %BoardGames.Command.TempelDesSchreckens.CreateGame{} = command
      ) do
    game
    |> Commanded.Aggregate.Multi.new()
    |> Commanded.Aggregate.Multi.execute(&create_game(&1, command.game_id, command.name))
    |> Commanded.Aggregate.Multi.execute(&join_game(&1, command.player_id))
  end

  def execute(game, %BoardGames.Command.TempelDesSchreckens.JoinGame{player_id: player_id}),
    do: join_game(game, player_id)

  @spec apply(BoardGames.TempelDesSchreckens.t(), BoardGames.Event.TempelDesSchreckens.GameCreated.t()) ::
          BoardGames.TempelDesSchreckens.t()
  def apply(%TempelDesSchreckens{} = game, %BoardGames.Event.TempelDesSchreckens.GameCreated{
        game_id: game_id,
        name: name
      }) do
    %{game | game_id: game_id, name: name}
  end

  def apply(%TempelDesSchreckens{} = game, %BoardGames.Event.TempelDesSchreckens.JoinedGame{
        player_id: player_id
      }) do
    %{game | players: [player_id]}
  end

  defp create_game(%TempelDesSchreckens{players: []}, id, name) when is_non_empty_string?(name) do
    %BoardGames.Event.TempelDesSchreckens.GameCreated{
      game_id: id,
      name: name
    }
  end

  defp create_game(_, _, _), do: {:error, :invalid_name}

  defp join_game(%TempelDesSchreckens{game_id: game_id} = game, player_id) when is_non_empty_string?(game_id) do
    %BoardGames.Event.TempelDesSchreckens.JoinedGame{
      game_id: game.game_id,
      player_id: player_id
    }
  end

  defp join_game(_, _), do: {:error, :game_is_not_in_progress}
end
