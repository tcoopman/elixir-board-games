defmodule BoardGames.TempelDesSchreckens.Event.RolesDealt do
  use TypedStruct

  @derive Jason.Encoder

  @typedoc """
  "adventurer" | "guardina"
  """
  @type role :: String.t()
  @type player_id :: String.t()

  typedstruct enforce: true do
    field :game_id, String.t()
    field :roles, Map.t(player_id(), role())
  end
end
