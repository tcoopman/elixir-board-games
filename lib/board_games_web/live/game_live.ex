defmodule BoardGamesWeb.GameLive do
  use Phoenix.HTML
  use BoardGamesWeb, :live_view

  @type status :: :waiting_for_players | :playing | :cancelled | :finished

  @impl true
  def mount(%{"id" => game_id}, _session, socket) do
    {:ok,
     socket
     |> assign(
       name: "Awesome game name",
       status: :waiting_for_players,
       players: players(game_id),
       allowed_actions: allowed_actions()
     )}
  end

  defp players(game_id) do
    BoardGames.TempelDesSchreckens.ReadModel.Game.State.players(game_id)
  end

  defp allowed_actions() do
    [
      %{
        action: :cancel,
        title: "Cancel",
        icon: "x-circle.svg",
        type: :secondary
      },
      %{
        action: :start_game,
        title: "Start",
        icon: "check.svg",
        type: :primary
      }
    ]
  end
end
