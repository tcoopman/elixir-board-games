defmodule BoardGames.Router do
  use Commanded.Commands.Router

  dispatch BoardGames.Command.JoinGame, to: BoardGames.Game, identity: :game_id

end
