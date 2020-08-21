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
    Registry.register(Registry.Events, :all_games, [])

    {:ok, assign(socket, submitting: false, changeset: CreateGame.changeset(%CreateGame{}))}
  end

  @impl true
  def handle_event("save", %{"create_game" => create_game}, socket) do
    changeset =
      %CreateGame{}
      |> CreateGame.changeset(create_game)

    create_game =
      changeset
      |> Ecto.Changeset.apply_action!(:update)

    :ok =
      BoardGames.App.dispatch(%BoardGames.TempelDesSchreckens.Command.CreateGame{
        name: create_game.name,
        game_id: create_game.name,
        player_id: create_game.player_id
      })

    {:noreply, assign(socket, submitting: true, changeset: changeset)}
  end

  @impl true
  def handle_info({:all_games_updated, _state}, socket) do
    {:noreply,
     socket
     |> push_redirect(to: "/game/1")
     |> put_flash(:success, "game created succesfully")
     |> assign(submitting: false)}
  end
end
