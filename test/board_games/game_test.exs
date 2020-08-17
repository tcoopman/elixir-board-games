defmodule BoardGames.GameTest do
  use BoardGames.InMemoryEventStoreCase
  use BoardGames.AggregateCase, aggregate: BoardGames.Game, async: true

  import Commanded.Assertions.EventAssertions

  test "Create a new game" do
    :ok =
      BoardGames.App.dispatch(%BoardGames.Command.CreateGame{
        player_id: "player_id",
        game_id: "game_id",
        name: "the game name",
        game_type: :tempel_des_schreckens
      })

    assert_receive_event(BoardGames.App, BoardGames.Event.GameCreated, fn event ->
      assert event.game_id == "game_id"
      assert event.player_id == "player_id"
      assert event.name == "the game name"
      assert event.game_type == :tempel_des_schreckens
    end)
  end

  test "Try to create a game with an unknown game type" do
    command = %BoardGames.Command.CreateGame{
        player_id: "player_id",
        game_id: "game_id",
        name: "the game name",
        game_type: :unknown_game_type
      }

    assert_error(command, {:error, :unknown_game_type})

  end
end
