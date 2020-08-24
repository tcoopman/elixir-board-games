defmodule BoardGamesWeb.LobbyLive do
  use Phoenix.HTML
  use BoardGamesWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    Registry.register(Registry.Events, :all_games, [])

    {:ok,
     socket
     |> assign(:games, BoardGames.ReadModel.AllGames.State.waiting_for_players())}
  end

  @impl true
  def handle_info({:all_games_updated, _state}, socket) do
    {:noreply,
     socket
     |> assign(:games, BoardGames.ReadModel.AllGames.State.waiting_for_players())}
  end
end
