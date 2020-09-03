defmodule BoardGames.TempelDesSchreckens.Event.RoomsDealt do
  use TypedStruct

  @derive Jason.Encoder

  @typedoc """
  "treasure" | "trap" | "empty"
  """
  @type room :: String.t()
  @type player_id :: String.t()

  typedstruct enforce: true do
    field :game_id, String.t()
    field :rooms, Map.t(player_id(), list(room()))
  end
end
