defmodule BoardGames.TempelDesSchreckens.ReadModel.GameTest do
  use BoardGames.InMemoryEventStoreCase
  use BoardGames.AggregateCase, aggregate: BoardGames.TempelDesSchreckens, async: false

  alias BoardGames.TempelDesSchreckens.ReadModel.Game.State
  alias BoardGames.ReadModel.Player

  describe "A game" do
    test "should model a valid game" do
      {events, _opts} = BoardGames.Test.Stories.waiting_for_players()

      handle_events(events)

      assert State.status() == :waiting_for_players
      assert_all(State.players(), fn %Player{} ->
        true
      end)
    end
  end

  defp handle_events(events), do: Enum.each(events, &State.handle_event/1)

  defp assert_all(items, fun) do
    assert Enum.count(items) > 0
    assert Enum.all?(items, &fun.(&1))
  end
end
