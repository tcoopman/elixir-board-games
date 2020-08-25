defmodule BoardGames.ReadModel.Player do
  use TypedStruct


  typedstruct enforce: true do
    field :id, String.t()
    field :name, String.t()
    field :bio, String.t()
    field :picture_url, String.t()
  end
end
