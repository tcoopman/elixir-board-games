defmodule BoardGames.GameTest do
  use BoardGames.InMemoryEventStoreCase

  import Commanded.Assertions.EventAssertions

  test "ensure any event of this type is published" do
    :ok = BoardGames.App.dispatch(%BoardGames.Command.JoinGame{player_id: "player_id", game_id: "game_id"})

    assert_receive_event(BoardGames.App, BoardGames.Event.JoinedGame, fn event ->
      assert event.game_id == "game_id"
      assert event.player_id == "player_id"
    end)
  end
end
