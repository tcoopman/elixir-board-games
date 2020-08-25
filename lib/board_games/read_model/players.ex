defmodule BoardGames.ReadModel.Players do
  alias BoardGames.ReadModel.Player

  def all() do
    [
      %Player{
        id: "Player1",
        name: "Leslie Alexander",
        bio: "Always a guardian, even if she says it's not true",
        picture_url:
          "https://images.unsplash.com/photo-1494790108377-be9c29b29330?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=facearea&facepad=2&w=256&h=256&q=80"
      },
      %Player{
        id: "Player2",
        name: "Michael Foster",
        bio: "I always tell the truth",
        picture_url:
          "https://images.unsplash.com/photo-1519244703995-f4e0f30006d5?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=facearea&facepad=2&w=256&h=256&q=80"
      },
      %Player{
        id: "Player3",
        name: "Tom Cook",
        bio: "Can you spot my tells?",
        picture_url:
          "https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=facearea&facepad=2&w=256&h=256&q=80"
      }
    ]
  end

  def by_id(player_id) when is_binary(player_id) do
    Enum.find_value(all(), {:error, :not_found}, fn
      %{id: ^player_id} = player -> {:ok, player}
      _ -> false
    end)
  end
end
