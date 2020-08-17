defmodule BoardGames.TempelDesSchreckens.Command.JoinGame do
  use TypedStruct

  typedstruct enforce: true do
    field :player_id, String.t()
    field :game_id, String.t()
  end
end
