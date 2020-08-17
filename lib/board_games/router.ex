defmodule BoardGames.Router do
  use Commanded.Commands.Router

  dispatch BoardGames.Command.TempelDesSchreckens.CreateGame, to: BoardGames.TempelDesSchreckens, identity: :game_id

end
