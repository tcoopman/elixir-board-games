defmodule BoardGames.Event.TempelDesSchreckens.GameCreated do
  use TypedStruct

  @derive Jason.Encoder

  typedstruct enforce: true do
    field :game_id, String.t()
    field :name, String.t()
  end
end
