defmodule BoardGames.Command.TempelDesSchreckens.CreateGame do
  use TypedStruct

  typedstruct enforce: true do
    field :player_id, String.t()
    field :game_id, String.t()
    field :name, String.t()
  end
end
