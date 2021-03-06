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

  def subtitle(joined, status, accepting_players) do
    if joined do
      case {status, accepting_players} do
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
        accepting_players ->
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
    state = Game.State.get(game_id, player_id)

    joined = Map.has_key?(state.joined_players, player_id)
    players = translate_players(state.joined_players, state.state_of_players)
    me = me(players, player_id, state.private)
    other_players = Enum.reject(players, &match?(%{id: ^player_id}, &1))

    socket
    |> assign(
      name: state.name,
      status: state.status,
      game_id: game_id,
      players: players,
      player_id: player_id,
      subtitle: subtitle(joined, state.status, state.accepting_players),
      allowed_actions: translate_allowed_actions(state.allowed_actions),
      me: me,
      other_players: other_players
    )
  end

  defp me(players, player_id, nil) do
    Enum.find(players, fn
      %{id: ^player_id} -> true
      _ -> false
    end)
  end

  defp me(players, player_id, private) do
    me =
      Enum.find(players, fn
        %{id: ^player_id} -> true
        _ -> false
      end)

    %{Map.merge(me, private) | role: map_role(private.role)}
  end

  defp translate_players(players, state_of_players) do
    state_of_players = state_of_players || []

    players
    |> Map.keys()
    |> Enum.map(fn player_id ->
      player = Map.fetch!(players, player_id)

      state =
        Enum.find(state_of_players, %{}, fn
          %{id: ^player_id} -> true
          _ -> false
        end)

      %{
        id: player.id,
        name: player.name,
        bio: player.bio,
        picture_url: player.picture_url,
        has_key: Map.get(state, :has_key),
        rooms: Map.get(state, :rooms, []) |> translate_rooms()
      }
    end)
  end

  defp translate_rooms(rooms),
    do:
      Enum.map(rooms, fn
        :closed ->
          %{
            image_url: "/images/closed_room.png",
            alt_text: "Closed Room"
          }
      end)

  defp map_role(:adventurer),
    do: %{
      name: "Adventurer",
      picture_url: "/images/adventurer.png"
    }

  defp map_role(:guardian),
    do: %{
      name: "Guardian",
      picture_url: "/images/guardian.png"
    }
end
