defmodule BoardGames.TempelDesSchreckensTest do
  use BoardGames.InMemoryEventStoreCase
  use BoardGames.AggregateCase, aggregate: BoardGames.Game, async: true

  import Commanded.Assertions.EventAssertions

  test "Create a new game" do
    :ok =
      BoardGames.App.dispatch(%BoardGames.Command.TempelDesSchreckens.CreateGame{
        player_id: "player_id",
        game_id: "game_id",
        name: "the game name",
      })

    assert_receive_event(BoardGames.App, BoardGames.Event.TempelDesSchreckens.GameCreated, fn event ->
      assert event.game_id == "game_id"
      assert event.name == "the game name"
    end)
    assert_receive_event(BoardGames.App, BoardGames.Event.TempelDesSchreckens.JoinedGame, fn event ->
      assert event.game_id == "game_id"
      assert event.player_id == "player_id"
    end)
  end

  test "Try to create a game with an empty name" do
    command = %BoardGames.Command.TempelDesSchreckens.CreateGame{
        player_id: "player_id",
        game_id: "game_id",
        name: "",
      }

    assert_error(command, {:error, :invalid_name})
  end

  describe "Join a game" do
    test "that is not yet created" do
    command = %BoardGames.Command.TempelDesSchreckens.JoinGame{
        player_id: "player_id",
        game_id: "game_id",
      }

    assert_error(command, {:error, :game_is_not_in_progress})
    end
  end
end
