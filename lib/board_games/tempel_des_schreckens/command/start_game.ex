defmodule BoardGames.TempelDesSchreckens.Command.StartGame do
  use TypedStruct

  typedstruct enforce: true do
    field :game_id, String.t()
  end
end
