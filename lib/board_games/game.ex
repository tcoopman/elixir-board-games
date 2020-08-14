defmodule BoardGames.Game do
  use TypedStruct

  alias __MODULE__

  typedstruct enforce: true do
    field :game_id, String.t()
    field :players, list(String.t()), default: []
  end

  def execute(%Game{players: []}, %BoardGames.Command.JoinGame{} = join_game) do
    %BoardGames.Event.JoinedGame{player_id: join_game.player_id, game_id: join_game.game_id}
  end

  def apply(%Game{} = game, %BoardGames.Event.JoinedGame{game_id: game_id, player_id: player_id}) do
    %{game | players: [player_id], game_id: game_id}
  end
end
