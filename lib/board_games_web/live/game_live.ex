defmodule BoardGamesWeb.GameLive do
  use Phoenix.HTML
  use BoardGamesWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end
end
