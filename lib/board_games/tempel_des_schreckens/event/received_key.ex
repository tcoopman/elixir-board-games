defmodule BoardGames.TempelDesSchreckens.Event.ReceivedKey do
  use TypedStruct

  @derive Jason.Encoder

  typedstruct enforce: true do
    field :game_id, String.t()
    field :player_id, String.t()
  end
end
