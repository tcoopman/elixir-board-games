defmodule BoardGames.Router do
  use Commanded.Commands.Router

  dispatch(BoardGames.TempelDesSchreckens.Command.CreateGame,
    to: BoardGames.TempelDesSchreckens,
    identity: :game_id
  )

  dispatch(BoardGames.TempelDesSchreckens.Command.JoinGame,
    to: BoardGames.TempelDesSchreckens,
    identity: :game_id
  )

  dispatch(BoardGames.TempelDesSchreckens.Command.StartGame,
    to: BoardGames.TempelDesSchreckens,
    identity: :game_id
  )
end
