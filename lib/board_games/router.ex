defmodule BoardGames.Router do
  use Commanded.Commands.Router

  dispatch BoardGames.Command.TempelDesSchreckens.CreateGame, to: BoardGames.Game, identity: :game_id

end
