defmodule BoardGames.Game do
  use TypedStruct

  alias __MODULE__

  typedstruct do
    field :game_id, String.t()
    field :players, list(String.t()), default: []
  end

  defguard has_valid_name?(name) when is_binary(name) and name != ""

  @spec execute(BoardGames.Game.t(), BoardGames.Command.TempelDesSchreckens.CreateGame.t()) ::
          {:error, :invalid_name} | BoardGames.Event.TempelDesSchreckens.GameCreated.t()
  def execute(
        %Game{players: []},
        %BoardGames.Command.TempelDesSchreckens.CreateGame{name: name} = create_game
      )
      when has_valid_name?(name) do
    %BoardGames.Event.TempelDesSchreckens.GameCreated{
      player_id: create_game.player_id,
      game_id: create_game.game_id,
      name: create_game.name
    }
  end

  def execute(%Game{players: []}, %BoardGames.Command.TempelDesSchreckens.CreateGame{}) do
    {:error, :invalid_name}
  end

  @spec apply(BoardGames.Game.t(), BoardGames.Event.TempelDesSchreckens.GameCreated.t()) ::
          BoardGames.Game.t()
  def apply(%Game{} = game, %BoardGames.Event.TempelDesSchreckens.GameCreated{
        game_id: game_id,
        player_id: player_id
      }) do
    %{game | players: [player_id], game_id: game_id}
  end
end
