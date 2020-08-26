defmodule BoardGames.TempelDesSchreckens.Event.GameCanBeStarted do
  use TypedStruct

  @derive Jason.Encoder

  typedstruct enforce: true do
    field :game_id, String.t()
  end
end
