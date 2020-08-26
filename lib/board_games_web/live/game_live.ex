defmodule BoardGamesWeb.GameLive do
  use Phoenix.HTML
  use BoardGamesWeb, :live_view

  alias BoardGames.TempelDesSchreckens.ReadModel.Game

  @type status :: :waiting_for_players | :playing | :cancelled | :finished

  @impl true
  def mount(%{"id" => game_id}, _session, socket) do
    Registry.register(Registry.Events, {:game, game_id}, [])

    # TODO what if the game_id does not exist?

    {:ok,
     socket
     |> assign(
       name: "Awesome game name",
       game_id: game_id,
       status: :waiting_for_players,
       players: players(game_id),
       player_id: "Player3",
       allowed_actions: allowed_actions(game_id, "Player3")
     )}
  end

  @impl true
  def handle_event("join_game", %{}, socket) do
    game_id = socket.assigns.game_id
    player_id = socket.assigns.player_id

    # TODO this can give an error
    :ok =
      BoardGames.App.dispatch(%BoardGames.TempelDesSchreckens.Command.JoinGame{
        game_id: game_id,
        player_id: player_id
      })

    {:noreply, socket}
  end

  @impl true
  def handle_info({:game_updated, _state}, socket) do
    game_id = socket.assigns.game_id
    player_id = socket.assigns.player_id

    {:noreply,
     socket
     |> assign(players: players(game_id), allowed_actions: allowed_actions(game_id, player_id))}
  end

  def subtitle(status, allowed_actions) do
    case status do
      :waiting_for_players ->
        can_join =
          Enum.any?(allowed_actions, fn
            %{action: "join_game"} -> true
            _ -> false
          end)

        if can_join do
          "Your are a currently a spectator, click join to enter the game"
        else
          "The game is waiting for more players"
        end
    end
  end

  defp players(game_id) do
    Game.State.players(game_id)
  end

  defp allowed_actions(game_id, player_id) do
    Game.State.allowed_actions(game_id, player_id)
    |> Enum.map(fn
      :join ->
        %{
          action: "join_game",
          title: "Join game",
          icon: "user-add.svg",
          type: :primary
        }

      :cancel ->
        %{
          action: "cancel_game",
          title: "Cancel",
          icon: "x-circle.svg",
          type: :secondary
        }

      :start ->
        %{
          action: "start_game",
          title: "Start game",
          icon: "check.svg",
          type: :primary
        }
    end)
  end
end
