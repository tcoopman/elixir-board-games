defmodule BoardGamesWeb.GameLive do
  use Phoenix.HTML
  use BoardGamesWeb, :live_view

  alias BoardGames.TempelDesSchreckens.ReadModel.Game

  @type status :: :waiting_for_players | :playing | :cancelled | :finished

  @impl true
  def mount(%{"id" => game_id}, _session, socket) do
    Registry.register(Registry.Events, {:game, game_id}, [])

    with {:ok, _state_pid} <- Game.Supervisor.state_by_game_id(game_id),
         state = Game.State.get(game_id) do
      player_id = "Player3"
      allowed_actions = Game.State.allowed_actions(state, player_id)

      {:ok,
       socket
       |> assign(
         name: state.name,
         game_id: game_id,
         players: state.players,
         player_id: player_id,
         subtitle: subtitle(state.joining_status, allowed_actions),
         allowed_actions: translate_allowed_actions(allowed_actions)
       )}
    else
      {:error, :game_not_found} ->
        {:ok,
         socket
         |> put_flash(:error, "Game #{game_id} cannot be found")
         |> push_redirect(to: "/")}
    end
  end

  @impl true
  def handle_event("join_game", %{}, socket) do
    game_id = socket.assigns.game_id
    player_id = socket.assigns.player_id

    with :ok <-
           BoardGames.App.dispatch(%BoardGames.TempelDesSchreckens.Command.JoinGame{
             game_id: game_id,
             player_id: player_id
           }) do
      {:noreply, socket}
    else
      {:error, error} ->
        # TODO give a human readable error message
        {:noreply,
         socket
         |> put_flash(:error, error)}
    end
  end

  @impl true
  def handle_info({:game_updated, _state}, socket) do
    game_id = socket.assigns.game_id
    player_id = socket.assigns.player_id
    state = Game.State.get(game_id)
    allowed_actions = Game.State.allowed_actions(state, player_id)

    {:noreply,
     socket
     |> assign(
       players: state.players,
       allowed_actions: translate_allowed_actions(allowed_actions),
       subtitle: subtitle(state.joining_status, allowed_actions)
     )}
  end

  def subtitle(joining_status, allowed_actions) do
    can_join = MapSet.member?(allowed_actions, :join)

    cond do
      can_join ->
        "Your are a currently a spectator, click join to enter the game"

      joining_status == :full ->
        "You are a spectator, enjoy watching the game"

      joining_status == :has_capacity ->
        "The game is waiting for more players"
    end
  end

  defp translate_allowed_actions(allowed_actions) do
    allowed_actions
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
