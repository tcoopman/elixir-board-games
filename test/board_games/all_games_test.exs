defmodule BoardGames.AllGamesTest do
  use BoardGames.InMemoryEventStoreCase
  use BoardGames.AggregateCase, aggregate: BoardGames.TempelDesSchreckens, async: true
  use ExUnit.Case, async: true

  alias BoardGames.TempelDesSchreckens.Event
  alias BoardGames.ReadModel.AllGames.State

  describe "Waiting for players" do
    test "no created games" do
      assert State.waiting_for_players() == []
    end

    test "some created games" do
      events = for i <- 1..10, do: %Event.GameCreated{game_id: "#{i}", name: "name_#{i}"}

      handle_events(events)

      assert Enum.count(State.waiting_for_players()) == 10
    end
  end

  defp handle_events(events), do: Enum.each(events, &State.handle_event/1)
end
