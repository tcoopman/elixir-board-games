defmodule BoardGames.TempelDesSchreckens.ReadModel.Game.EventHandler do
  use Commanded.Event.Handler,
    application: BoardGames.App,
    subscription_opts: [transient: true]

  alias BoardGames.TempelDesSchreckens.ReadModel.Game

  def init(config) do
    {game_id, config} = Keyword.pop!(config, :game_id)

    config =
      config
      |> Keyword.put(:name, Module.concat(__MODULE__, game_id))
      |> Keyword.put(:subscribe_to, game_id)
      |> Keyword.put(:state, %{game_id: game_id, pid: nil})

    {:ok, config}
  end

  def handle(event, %{state: state}) do
    with pid <- get_pid!(state),
         :ok <- Game.State.handle_event(pid, event),
         :ok <- dispatch(state.game_id) do
      {:ok, %{state | pid: pid}}
    end
  end

  defp get_pid!(%{pid: nil, game_id: game_id}) do
    {:ok, pid} = Game.Supervisor.state_by_game_id(game_id)
    pid
  end

  defp get_pid!(%{pid: pid}) when not is_nil(pid), do: pid

  defp dispatch(game_id) do
    Registry.dispatch(Registry.Events, {:game, game_id}, fn entries ->
      for {pid, _} <- entries, do: send(pid, {:game_updated, nil})
    end)
  end
end
