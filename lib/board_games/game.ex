defmodule BoardGames.Game do
  use TypedStruct

  alias __MODULE__

  typedstruct do
    field :game_id, String.t()
    field :players, list(String.t()), default: []
  end

  @spec execute(BoardGames.Game.t(), BoardGames.Command.CreateGame.t()) ::
          {:error, :unknown_game_type} | BoardGames.Event.GameCreated.t()
  def execute(%Game{players: []}, %BoardGames.Command.CreateGame{game_type: :tempel_des_schreckens} = create_game) do
    %BoardGames.Event.GameCreated{
      player_id: create_game.player_id,
      game_id: create_game.game_id,
      name: create_game.name,
      game_type: create_game.game_type
    }
  end

  def execute(%Game{players: []}, %BoardGames.Command.CreateGame{}) do
    {:error, :unknown_game_type}
  end

  @spec apply(BoardGames.Game.t(), BoardGames.Event.GameCreated.t()) :: BoardGames.Game.t()
  def apply(%Game{} = game, %BoardGames.Event.GameCreated{game_id: game_id, player_id: player_id}) do
    %{game | players: [player_id], game_id: game_id}
  end
end
