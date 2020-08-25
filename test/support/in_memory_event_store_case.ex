defmodule BoardGames.InMemoryEventStoreCase do
  use ExUnit.CaseTemplate

  setup do
    on_exit(fn ->
      :ok = Application.stop(:board_games)
      :ok = Application.stop(:commanded)

    {:ok, _apps} = Application.ensure_all_started(:board_games)
    end)
  end
end
