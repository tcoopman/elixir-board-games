defmodule BoardGamesWeb.GameLive do
  use Phoenix.HTML
  use BoardGamesWeb, :live_view

  @type status :: :waiting_for_players | :playing | :cancelled | :finished

  @impl true
  def mount(%{"id" => game_id}, _session, socket) do
    Registry.register(Registry.Events, {:game, game_id}, [])

    {:ok,
     socket
     |> assign(
       name: "Awesome game name",
       game_id: game_id,
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

  @impl true
  def handle_info({:game_updated, _state}, socket) do
    players = players(socket.assigns.game_id)

    {:noreply,
     socket
     |> assign(:players, players)}
  end
end
