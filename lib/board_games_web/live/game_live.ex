defmodule BoardGamesWeb.GameLive do
  use Phoenix.HTML
  use BoardGamesWeb, :live_view

  alias BoardGames.TempelDesSchreckens.ReadModel.Game

  @type status :: :waiting_for_players | :playing | :cancelled | :finished

  @impl true
  def mount(%{"id" => game_id}, _session, socket) do
    Registry.register(Registry.Events, {:game, game_id}, [])

    player_id = "Player3"

    with {:ok, _state_pid} <- Game.Supervisor.state_by_game_id(game_id) do
      {:ok, assign_game(socket, game_id, player_id)}
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
  def handle_event("start_game", %{}, socket) do
    game_id = socket.assigns.game_id

    with :ok <-
           BoardGames.App.dispatch(%BoardGames.TempelDesSchreckens.Command.StartGame{
             game_id: game_id
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

    {:noreply, assign_game(socket, game_id, player_id)}
  end

  def subtitle(%Game.State{} = state, %Game.State.PlayerState{} = player_state) do
    if player_state.joined do
      case {state.status, state.accepting_players} do
        {:can_be_started, true} ->
          "You can wait for more players, or start the game"

        {:can_be_started, false} ->
          "No more players can join. The game is ready to start"

        {:playing, _} ->
          "The game is in progress"

        {:waiting_for_players, _} ->
          "The game is waiting for more players"
      end
    else
      cond do
        state.accepting_players ->
          "Your are a currently a spectator, click join to enter the game"

        true ->
          "You are a spectator, enjoy watching the game"
      end
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

  defp assign_game(socket, game_id, player_id) do
    with {%Game.State{} = state, %Game.State.PlayerState{} = player_state} <-
           Game.State.get(game_id, player_id) do
      socket
      |> assign(
        name: state.name,
        status: :playing,
        game_id: game_id,
        players: state.players |> translate_players(),
        player_id: player_id,
        subtitle: subtitle(state, player_state),
        allowed_actions: translate_allowed_actions(player_state.allowed_actions),
        player_with_key: state.player_with_key
      )
    end
  end

  defp translate_players(players) do
    players
    |> Map.values()
    |> Enum.map(fn player ->
      %{
        id: player.id,
        name: player.player_info.name,
        bio: player.player_info.bio,
        picture_url: player.player_info.picture_url,
        has_key: player.has_key,
        cards: cards()
      }
    end)
  end

  defp cards(),
    do:
      for(
        _ <- 1..5,
        do: %{
          image_url: "/images/closed_room.png",
          alt_text: "Closed Room"
        }
      )
end
