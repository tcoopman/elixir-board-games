defmodule BoardGames.Repo do
  use Ecto.Repo,
    otp_app: :board_games,
    adapter: Ecto.Adapters.Postgres
end
