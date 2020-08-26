defmodule BoardGamesWeb.GameLive do
  use Phoenix.HTML
  use BoardGamesWeb, :live_view

  alias BoardGames.TempelDesSchreckens.ReadModel.Game

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
       player_id: "Player3",
       allowed_actions: allowed_actions(game_id, "Player4")
     )}
  end

  @impl true
  def handle_event("join_game", %{}, socket) do
    game_id = socket.assigns.game_id
    player_id = socket.assigns.player_id
    :ok =
      BoardGames.App.dispatch(%BoardGames.TempelDesSchreckens.Command.JoinGame{
        game_id: game_id,
        player_id: player_id
      })

    {:noreply, socket}
  end

  defp players(game_id) do
    Game.State.players(game_id)
  end

  defp allowed_actions(game_id, player_id) do
    Game.State.allowed_actions(game_id, player_id)
    |> Enum.map(fn :join ->
      %{
        action: "join_game",
        title: "Join game",
        icon: "user-add.svg",
        type: :primary
      }
    end)
  end

  @impl true
  def handle_info({:game_updated, _state}, socket) do
    game_id = socket.assigns.game_id
    player_id = socket.assigns.player_id

    {:noreply,
     socket
     |> assign(players: players(game_id), allowed_actions: allowed_actions(game_id, player_id))}
  end
end
