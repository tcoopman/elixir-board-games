defmodule BoardGames.TempelDesSchreckens.Event.GameStarted do
  use TypedStruct

  typedstruct enforce: true do
    field :game_id, String.t()
  end
end
