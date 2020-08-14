defmodule BoardGames.App do
  use Commanded.Application, otp_app: :board_games

  router BoardGames.Router
end
