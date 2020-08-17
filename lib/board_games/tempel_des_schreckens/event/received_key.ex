defmodule BoardGames.TempelDesSchreckens.Event.ReceivedKey do
  use TypedStruct

  typedstruct enforce: true do
    field :game_id, String.t()
    field :player_id, String.t()
  end
end
