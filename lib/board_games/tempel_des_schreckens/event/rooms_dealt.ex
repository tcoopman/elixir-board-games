defmodule BoardGames.TempelDesSchreckens.Event.RoomsDealt do
  use TypedStruct

  @type room :: :empty | :trap | :treasure

  typedstruct enforce: true do
    field :game_id, String.t()
    field :rooms, list({String.t(), room()})
  end
end