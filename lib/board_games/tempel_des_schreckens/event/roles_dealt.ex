defmodule BoardGames.TempelDesSchreckens.Event.RolesDealt do
  use TypedStruct

  @type role :: :adventurer | :guardian

  typedstruct enforce: true do
    field :game_id, String.t()
    field :roles, list({String.t(), role()}), default: []
  end
end
