defmodule BoardGames.TempelDesSchreckens.ReadModel.Game.Supervisor do
  use Supervisor

  alias BoardGames.TempelDesSchreckens.ReadModel.Game

  defmodule EventStateSupervisor do
    use Supervisor

    def start_link(init_arg) do
      Supervisor.start_link(__MODULE__, init_arg)
    end

    @impl true
    def init(args) do
      game_id = Keyword.fetch!(args, :game_id)

      children = [
        Supervisor.child_spec({Game.EventHandler, [game_id: game_id]},
          id: {Game.EventHandler, game_id}
        ),
        Supervisor.child_spec(Game.State,
          id: {Game.State, game_id}
        )
      ]

      Supervisor.init(children, strategy: :one_for_all)
    end
  end

  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    Supervisor.init([], strategy: :one_for_one)
  end

  def start_event_handler(game_id) do
    spec =
      {EventStateSupervisor, game_id: game_id}
      |> Supervisor.child_spec(id: {EventStateSupervisor, game_id})

    result = Supervisor.start_child(__MODULE__, spec)
    result
  end

  def state_by_game_id(game_id) do
    {_, pid, _, _} =
      Supervisor.which_children(__MODULE__)
      |> Enum.find(fn
        {{_, ^game_id}, _, _, _} -> true
        _ -> false
      end)

    {_, state_pid, _, _} =
      Supervisor.which_children(pid)
      |> Enum.find(fn
        {{Game.State, _}, _, _, _} -> true
        _ -> false
      end)

    state_pid
  end
end
