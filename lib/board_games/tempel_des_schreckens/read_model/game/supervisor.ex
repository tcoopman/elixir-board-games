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
    with all_games <- Supervisor.which_children(__MODULE__),
         {:ok, supervisor_pid} <-
           Enum.find_value(all_games, {:error, :game_not_found}, fn
             {{_, ^game_id}, pid, _, _} -> {:ok, pid}
             _ -> false
           end),
         children <- Supervisor.which_children(supervisor_pid),
         {:ok, state_pid} <-
           Enum.find_value(children, {:error, :state_not_found}, fn
             {{Game.State, _}, pid, _, _} -> {:ok, pid}
             _ -> false
           end) do
      {:ok, state_pid}
    end
  end
end
