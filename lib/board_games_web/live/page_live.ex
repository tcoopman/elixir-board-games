defmodule BoardGamesWeb.PageLive do
  use Phoenix.HTML
  use BoardGamesWeb, :live_view

  defmodule CreateGame do
    use Ecto.Schema
    import Ecto.Changeset

    schema "create_game" do
      field :name
      field :player_id
    end

    def changeset(create_game, params \\ %{}) do
      create_game
      |> cast(params, [:name, :player_id])
      |> validate_required([:name, :player_id])
    end
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket, query: "", results: %{}, changeset: CreateGame.changeset(%CreateGame{}, %{}))}
  end

  @impl true
  def handle_event("save", %{"create_game" => create_game}, socket) do
    create_game =
      %CreateGame{}
      |> CreateGame.changeset(create_game)
      |> Ecto.Changeset.apply_action!(:update)

    BoardGames.App.dispatch(%BoardGames.TempelDesSchreckens.Command.CreateGame{
      name: create_game.name,
      game_id: "TODO",
      player_id: create_game.player_id
    })

    {:noreply, socket}
  end
end
