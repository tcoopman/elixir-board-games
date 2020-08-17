defmodule BoardGames.Event.GameCreated do
  use TypedStruct

  @type game_type :: :tempel_des_schreckens

  @derive Jason.Encoder

  typedstruct enforce: true do
    field :player_id, String.t()
    field :game_id, String.t()
    field :name, String.t()
    field :game_type, game_type()
  end
end
