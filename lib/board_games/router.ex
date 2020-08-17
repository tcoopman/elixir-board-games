defmodule BoardGames.Router do
  use Commanded.Commands.Router

  dispatch BoardGames.Command.CreateGame, to: BoardGames.Game, identity: :game_id

end
