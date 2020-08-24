defmodule BoardGamesWeb.GameLive do
  use Phoenix.HTML
  use BoardGamesWeb, :live_view

  @type status :: :waiting | :playing | :cancelled | :finished

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(
       name: "Awesome game name",
       status: :waiting,
       players: players(),
       allowed_actions: allowed_actions()
     )}
  end

  defp players() do
    [
      %{
        name: "Leslie Alexander",
        bio: "Always a guardian, even if she says it's not true",
        picture_url:
          "https://images.unsplash.com/photo-1494790108377-be9c29b29330?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=facearea&facepad=2&w=256&h=256&q=80"
      },
      %{
        name: "Michael Foster",
        bio: "I always tell the truth",
        picture_url:
          "https://images.unsplash.com/photo-1519244703995-f4e0f30006d5?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=facearea&facepad=2&w=256&h=256&q=80"
      },
      %{
        name: "Tom Cook",
        bio: "Can you spot my tells?",
        picture_url:
          "https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=facearea&facepad=2&w=256&h=256&q=80"
      }
    ]
  end

  defp allowed_actions() do
    [
      %{
        action: :cancel,
        title: "Cancel",
        icon: "x-circle.svg"
      }
    ]
  end
end
