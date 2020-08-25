defmodule BoardGames.TempelDesSchreckens.ReadModel.GameTest do
  use BoardGames.InMemoryEventStoreCase
  use BoardGames.AggregateCase, aggregate: BoardGames.TempelDesSchreckens, async: false

  alias BoardGames.TempelDesSchreckens.ReadModel.Game
  alias BoardGames.ReadModel.Player

  setup do
    game_id = UUID.uuid4()
    Game.Supervisor.start_event_handler(game_id)

    [game_id: game_id]
  end

  describe "A game" do
    test "should model a valid game", %{game_id: game_id} do
      {events, _opts} = BoardGames.Test.Stories.waiting_for_players(game_id: game_id)

      handle_events(events)

      assert Game.State.status(game_id) == :waiting_for_players
      assert_all(Game.State.players(game_id), fn %Player{} ->
        true
      end)
    end
  end

  defp handle_events(events), do: Enum.each(events, &Game.State.handle_event/1)

  defp assert_all(items, fun) do
    assert Enum.count(items) > 0
    assert Enum.all?(items, &fun.(&1))
  end
end
